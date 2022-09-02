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
    metadata = {}

    # Metadata from the bag
    bag = bagit.Bag(path)

    # Regex to match essence paths in bag
    regex = re.compile("data/representations/.*/data/.*")

    for filepath, fixity in bag.entries.items():
        if regex.match(filepath):
            metadata["filename"] = filepath
            metadata["file_extension"] = Path(filepath).suffix

    # Metadata from package mets.xml
    mets_path = Path(path, "data/mets.xml")
    root = etree.parse(str(mets_path))
    metadata["cp_name"] = root.xpath(
        "//*[local-name() = 'metsHdr']/*[local-name() = 'agent' and @ROLE = 'CREATOR' and @TYPE = 'ORGANIZATION'][1]/*[local-name() = 'name']/text()"
    )[0]
    metadata["cp_id"] = root.xpath(
        "//*[local-name() = 'metsHdr']/*[local-name() = 'agent' and @ROLE = 'CREATOR' and @TYPE = 'ORGANIZATION'][1]/*[local-name() = 'note' and @*[local-name()='NOTETYPE'] = 'IDENTIFICATIONCODE']/text()"
    )[0]

    # Metadata from the preservation data of the representation
    premis_path = Path(
        path, "data/representations/representation_1/metadata/preservation/premis.xml"
    )
    premis_namespaces = {
        "premis": "http://www.loc.gov/premis/v3",
        "xsi": "http://www.w3.org/2001/XMLSchema-instance",
    }
    root_premis = etree.parse(str(premis_path))
    metadata["original_filename"] = root_premis.xpath(
        "/premis:premis/premis:object[@xsi:type='premis:file']/premis:originalName/text()",
        namespaces=premis_namespaces,
    )[0]
    metadata["md5"] = root_premis.xpath(
        "/premis:premis/premis:object[@xsi:type='premis:file']/premis:objectCharacteristics/premis:fixity/premis:messageDigest/text()",
        namespaces=premis_namespaces,
    )[0]

    # Generated metadata
    metadata["pid"] = get_pid(configParser.app_cfg["aip-creator"]["pid_url"])

    # Batch ID
    metadata["batch_id"] = ""
    try:
        metadata["batch_id"] = bag.info["Meemoo-Batch-Identifier"]
    except KeyError:
        pass

    return metadata


def create_sidecar(path: str, metadata: dict):
    # Parameters not present in the input XML
    original_filename = metadata["original_filename"]
    cp_name = metadata["cp_name"]
    cp_id = metadata["cp_id"]
    md5 = metadata["md5"]
    pid = metadata["pid"]

    # The XSLT
    xslt_path = Path("metadata.xslt")
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
        batch_id=etree.XSLT.strparam(str(metadata["batch_id"])),
    ).getroot()
    return etree.tostring(tr, pretty_print=True, encoding="UTF-8", xml_declaration=True)


def handle_event(event: Event):
    """
    Handles an incoming pulsar event.
    If the event has a succesful outcome, a sidecar will be created.
    Sidecar and essence will be moved to the configured aip_folder and an event will be produced.
    """
    if not event.has_successful_outcome():
        log.info(f"Dropping non succesful event: {event.get_data()}")
        return

    log.debug(f"Incoming event: {event.get_data()}")

    # Path to unzipped bag
    path: str = event.get_data()["destination"]

    # Extract metadata from bag info and mets xmls
    metadata: dict = extract_metadata(path)

    # Build a mediahaven sidecar with extracted xmls
    sidecar = create_sidecar(path, metadata)

    filename = metadata["filename"]
    essence_filepath = Path(path, filename)
    sidecar_filepath = Path(path, filename).with_suffix(".xml")

    # Write sidecar to file
    with open(sidecar_filepath, "wb") as xml_file:
        xml_file.write(sidecar)

    # Move file(s) to AIP folder with PID as filename(s)
    aip_filepath = Path(
        configParser.app_cfg["aip-creator"]["aip_folder"], metadata["pid"]
    )

    shutil.move(essence_filepath, aip_filepath.with_suffix(metadata["file_extension"]))
    shutil.move(sidecar_filepath, aip_filepath.with_suffix(".xml"))

    # Send event on topic
    data = {
        "source": path,
        "host": configParser.app_cfg["aip-creator"]["host"],
        "paths": [
            str(aip_filepath.with_suffix(metadata["file_extension"])),
            str(aip_filepath.with_suffix(".xml")),
        ],
        "cp_id": metadata["cp_id"],
        "type": "pair",
        "pid": metadata["pid"],
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
