#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pathlib import Path


def load_resource(filepath: Path):
    with open(filepath, "r", encoding="utf-8") as f:
        contents = f.read()
    return contents
