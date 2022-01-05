from pathlib import Path
import os
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

client = pulsar.Client(f"pulsar://{configParser.app_cfg['pulsar']['host']}:{configParser.app_cfg['pulsar']['port']}")


@retry(pulsar.ConnectError, tries=10, delay=1, backoff=2)
def create_producer():
    return client.create_producer(configParser.app_cfg['aip-creator']['producer_topic'])


@retry(pulsar.ConnectError, tries=10, delay=1, backoff=2)
def subscribe():
    return client.subscribe(configParser.app_cfg['aip-creator']['consumer_topic'], APP_NAME)


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
            metadata["md5"] = fixity["md5"]
            metadata["basename"] = Path(filepath).name
            metadata["filename"] = filepath
            metadata["file_extension"] = Path(filepath).suffix

    # Metadata from mets.xml
    mets_path = Path(path, "data/mets.xml")
    root = etree.parse(str(mets_path))
    metadata["cp_id"] = root.xpath(
        "//*[local-name() = 'metsHdr']/*[local-name() = 'agent' and @ROLE = 'SUBMITTING AGENT'][1]/*[local-name() = 'note' and @*[local-name()='NOTETYPE'] = 'IDENTIFICATION CODE']/text()"
    )[0]

    # Generated metadata
    metadata["pid"] = get_pid(configParser.app_cfg['aip-creator']['pid_url'])

    return metadata


def create_sidecar(metadata: dict):
    basename = metadata["basename"]
    cp_id = metadata["cp_id"]
    md5 = metadata["md5"]
    pid = metadata["pid"]
    sp_name = "sipin"

    root = etree.Element("MediaHAVEN_external_metadata")
    etree.SubElement(root, "title").text = basename

    mdprops = etree.SubElement(root, "MDProperties")
    etree.SubElement(mdprops, "CP_id").text = cp_id
    etree.SubElement(mdprops, "sp_name").text = sp_name
    etree.SubElement(mdprops, "PID").text = pid
    etree.SubElement(mdprops, "dc_source").text = basename
    etree.SubElement(mdprops, "dc_identifier_localid").text = basename.split(".")[0]

    local_ids = etree.SubElement(mdprops, "dc_identifier_localids")
    etree.SubElement(local_ids, "id").text = basename

    etree.SubElement(root, "md5").text = md5

    return etree.tostring(
        root, pretty_print=True, encoding="UTF-8", xml_declaration=True
    )

def handle_event(event: Event):
    """
    Handles an incoming pulsar event.
    If the event has a succesful outcome, a sidecar will be created.
    Sidecar and essence will be moved to the configured aip_folder and an event will be produced.
    """
    if not event.has_successful_outcome:
        return

    # Path to unzipped bag
    path = event.get_data()["destination"]

    # Extract metadata from bag info and mets xmls
    metadata: dict = extract_metadata(path)

    # Build a mediahaven sidecar with extracted xmls
    sidecar = create_sidecar(metadata)

    filename = metadata["filename"]
    essence_filepath = Path(path, filename)
    sidecar_filepath = Path(path, filename).with_suffix(".xml")

    # Write sidecar to file
    with open(sidecar_filepath, "wb") as xml_file:
        xml_file.write(sidecar)

    # Move file(s) to AIP folder with PID as filename(s)
    aip_filepath = Path(configParser.app_cfg['aip-creator']['aip_folder'], metadata["pid"])

    shutil.move(
        essence_filepath, aip_filepath.with_suffix(metadata["file_extension"])
    )
    shutil.move(sidecar_filepath, aip_filepath.with_suffix(".xml"))

    # Send event on topic
    data = {
        "host": configParser.app_cfg['aip-creator']['host'],
        "paths": [
            str(aip_filepath.with_suffix(metadata["file_extension"])),
            str(aip_filepath.with_suffix(".xml")),
        ],
        "cp_id": metadata["cp_id"],
        "type": "pair",
        "outcome": EventOutcome.SUCCESS,
        "message": f"AIP created: sidecar ingest for {filename}",
    }

    send_event(data, path, event.correlation_id)

def send_event(data: dict, subject: str, correlation_id: str):
    attributes = EventAttributes(
        type=configParser.app_cfg['aip-creator']['producer_topic'],
        source=APP_NAME,
        subject=subject,
        correlation_id=correlation_id,
    )

    event = Event(attributes, data)
    create_msg = PulsarBinding.to_protocol(
        event, CEMessageMode.STRUCTURED
    )

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
