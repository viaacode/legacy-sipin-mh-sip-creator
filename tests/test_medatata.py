#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from pathlib import Path

import pytest
from lxml import etree

from tests import load_resource


@pytest.mark.parametrize(
    "premis_path,output_path",
    [
        ("premis.xml", "mhs.xml"),
        ("premis_xdcam.xml", "mhs_xdcam.xml"),
    ],
)
def test_transform(premis_path, output_path):
    # Arrange
    metadata_path = Path("tests", "resources", "dc.xml")
    premis_path = Path("tests", "resources", premis_path)
    xslt_path = Path("metadata.xslt")
    cp_name = "CP name"
    cp_id = "CP ID"
    pid = "PID"
    original_filename = "name"
    md5 = "md5"

    # Act
    xslt = etree.parse(str(xslt_path.resolve()))
    transform = etree.XSLT(xslt)
    transformed = transform(
        etree.parse(str(metadata_path)),
        cp_name=etree.XSLT.strparam(cp_name),
        cp_id=etree.XSLT.strparam(cp_id),
        pid=etree.XSLT.strparam(pid),
        original_filename=etree.XSLT.strparam(original_filename),
        md5=etree.XSLT.strparam(md5),
        premis_path=etree.XSLT.strparam(str(premis_path)),
    )
    transformed_xml = etree.tostring(
        transformed,
        pretty_print=True,
        xml_declaration=True,
        encoding="UTF-8",
    ).strip()
    expected_output_xml = load_resource(Path("tests", "resources", output_path))

    # Assert
    assert transformed_xml == expected_output_xml
