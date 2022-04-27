#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from pathlib import Path

from lxml import etree

from tests import load_resource


def test_transform():
    # Arrange
    metadata_path = Path("tests", "resources", "dc.xml")
    xslt_path = Path("metadata.xslt")

    # Act
    xslt = etree.parse(str(xslt_path.resolve()))
    transform = etree.XSLT(xslt)
    transformed = transform(etree.parse(str(metadata_path)))
    transformed_xml = etree.tostring(
        transformed,
        pretty_print=True,
        xml_declaration=True,
        encoding="UTF-8",
    ).strip()
    expected_output_xml = load_resource(Path("tests", "resources", "mhs.xml"))

    # Assert
    assert transformed_xml == expected_output_xml
