from pathlib import Path
import re
import requests
import shutil

from lxml import etree
from retry import retry
import bagit
import pulsar
from viaa.configuration import ConfigParser
from viaa.observability import logging

from cloudevents.events import (
    CEMessageMode,
    Event,
    EventOutcome,
    EventAttributes,
    PulsarBinding,
)

APP_NAME = "aip-creator"

configParser = ConfigParser()
log = logging.get_logger(__name__, config=configParser)

client = pulsar.Client(
    f"pulsar://{configParser.app_cfg['pulsar']['host']}:{configParser.app_cfg['pulsar']['port']}"
)


@retry(pulsar.ConnectError, tries=10, delay=1, backoff=2)
def create_producer():
    return client.create_producer(configParser.app_cfg["aip-creator"]["producer_topic"])


@retry(pulsar.ConnectError, tries=10, delay=1, backoff=2)
def subscribe():
    return client.subscribe(
        configParser.app_cfg["aip-creator"]["consumer_topic"], APP_NAME
    )


producer = create_producer()
consumer = subscribe()


def get_pid(url):
    resp = requests.get(url)
    pid = resp.json()[0]["id"]

    return pid


def extract_metadata(path: str):
    package_metadata = {}
    items_metadata = []

    # Generated metadata
    package_metadata["pid"] = get_pid(configParser.app_cfg["aip-creator"]["pid_url"])
    
    # Metadata from the bag
    bag = bagit.Bag(path)

    # Regex to match essence paths in bag
    regex = re.compile("data/representations/.*/data/.*")

    for filepath, fixity in bag.entries.items():
        if regex.match(filepath):
            log.debug(f"'{filepath}' matches regex.")
            item_metadata = {
                    "filepath": filepath,
                    "filename": Path(filepath).name,
                    "file_extension": Path(filepath).suffix,
                    "fixity": fixity["md5"]
                }
            if Path(filepath).suffix in ["srt"]:
                item_metadata["pid"] = f"{package_metadata['pid']}_{item_metadata['file_extension']}"
                item_metadata["is_collateral"] = True
            else:
                item_metadata["pid"] = package_metadata['pid']
                item_metadata["is_collateral"] = False

            items_metadata.append(item_metadata)

    # Metadata from package mets.xml
    mets_path = Path(path, "data/mets.xml")
    root = etree.parse(str(mets_path))
    package_metadata["cp_name"] = root.xpath(
        "//*[local-name() = 'metsHdr']/*[local-name() = 'agent' and @ROLE = 'CREATOR' and @TYPE = 'ORGANIZATION'][1]/*[local-name() = 'name']/text()"
    )[0]
    package_metadata["cp_id"] = root.xpath(
        "//*[local-name() = 'metsHdr']/*[local-name() = 'agent' and @ROLE = 'CREATOR' and @TYPE = 'ORGANIZATION'][1]/*[local-name() = 'note' and @*[local-name()='NOTETYPE'] = 'IDENTIFICATIONCODE']/text()"
    )[0]



    # Batch ID
    package_metadata["batch_id"] = ""
    try:
        package_metadata["batch_id"] = bag.info["Meemoo-Batch-Identifier"]
    except KeyError:
        pass

    # Meemoo workflow
    package_metadata["meemoo_workflow"] = ""
    try:
        package_metadata["meemoo_workflow"] = bag.info["Meemoo-Workflow"]
    except KeyError:
        pass

    package_metadata["items"] = items_metadata

    return package_metadata


def create_sidecar(path: str, metadata: dict, item: dict):
    # Parameters not present in the input XML
    original_filename = item["filename"]
    md5 = item["fixity"]
    pid = item["pid"]
    cp_name = metadata["cp_name"]
    cp_id = metadata["cp_id"]
    batch_id = metadata["batch_id"]
    meemoo_workflow = metadata["meemoo_workflow"]

    # Check if item is collateral, currently only srts are supported
    if item["is_collateral"]:
        xslt_path = Path("collateral_metadata.xslt")
    else:
        xslt_path = Path("essence_metadata.xslt")
    xslt = etree.parse(str(xslt_path.resolve()))

    # Descriptive metadata
    # TODO: Get the paths dynamically
    metadata_path = Path(path, "data/metadata/descriptive/dc.xml")
    premis_path = Path(path, "data/metadata/preservation/premis.xml")

    # XSLT transformation
    transform = etree.XSLT(xslt)
    tr = transform(
        etree.parse(str(metadata_path)),
        cp_id=etree.XSLT.strparam(cp_id),
        cp_name=etree.XSLT.strparam(cp_name),
        pid=etree.XSLT.strparam(pid),
        original_filename=etree.XSLT.strparam(original_filename),
        md5=etree.XSLT.strparam(md5),
        premis_path=etree.XSLT.strparam(str(premis_path)),
        batch_id=etree.XSLT.strparam(batch_id),
        meemoo_workflow=etree.XSLT.strparam(meemoo_workflow),
    ).getroot()

    return etree.tostring(tr, pretty_print=True, encoding="UTF-8", xml_declaration=True)


def handle_event(event: Event):
    """
    Handles an incoming pulsar event.
    If the event has a succesful outcome, one or more sidecar(s) will be created.
    Sidecar(s) and essence(s) will be moved to the configured aip_folder and one or more event(s) will be produced.
    """
    if not event.has_successful_outcome():
        log.info(f"Dropping non succesful event: {event.get_data()}")
        return

    log.debug(f"Incoming event: {event.get_data()}")

    # Path to unzipped bag
    path: str = event.get_data()["destination"]

    # Extract metadata from bag info and mets xmls
    metadata: dict = extract_metadata(path)

    log.debug(f"SIP has {len(metadata['items'])} item(s).")

    # Build one or more mediahaven sidecar(s) with extracted xmls
    for item in metadata["items"]:
        sidecar = create_sidecar(path, metadata, item)

        filename = item["filepath"]
        essence_filepath = Path(path, filename)
        sidecar_filepath = Path(path, filename).with_suffix(".xml")

        # Write sidecar to file
        with open(sidecar_filepath, "wb") as xml_file:
            xml_file.write(sidecar)

        # Move file(s) to AIP folder with PID as filename(s)
        aip_filepath = Path(
            configParser.app_cfg["aip-creator"]["aip_folder"], item["pid"]
        )

        shutil.move(essence_filepath, aip_filepath.with_suffix(item["file_extension"]))
        shutil.move(sidecar_filepath, aip_filepath.with_suffix(".xml"))

        # Send event on topic
        data = {
            "source": path,
            "host": configParser.app_cfg["aip-creator"]["host"],
            "paths": [
                str(aip_filepath.with_suffix(item["file_extension"])),
                str(aip_filepath.with_suffix(".xml")),
            ],
            "cp_id": metadata["cp_id"],
            "type": "pair",
            "pid": item["pid"],
            "outcome": EventOutcome.SUCCESS,
            "message": f"AIP created: sidecar ingest for {filename}",
        }

        log.info(data["message"])
        send_event(data, path, event.correlation_id)


def send_event(data: dict, subject: str, correlation_id: str):
    attributes = EventAttributes(
        type=configParser.app_cfg["aip-creator"]["producer_topic"],
        source=APP_NAME,
        subject=subject,
        correlation_id=correlation_id,
    )

    event = Event(attributes, data)
    create_msg = PulsarBinding.to_protocol(event, CEMessageMode.STRUCTURED)

    producer.send(
        create_msg.data,
        properties=create_msg.attributes,
        event_timestamp=event.get_event_time_as_int(),
    )


if __name__ == "__main__":
    while True:
        msg = consumer.receive()
        try:
            event = PulsarBinding.from_protocol(msg)

            handle_event(event)
            consumer.acknowledge(msg)

        except Exception as e:
            # Message failed to be processed
            log.error(e)
            consumer.negative_acknowledge(msg)
    client.close()
