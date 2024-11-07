#!/usr/bin/env python3
"""Install Speculos"""
import pathlib
import tempfile
from distutils.spawn import find_executable
from setuptools.command.build_py import build_py as _build_py
from setuptools import setup


class BuildSpeculos(_build_py):
    """
    Extend "setup.py build_py" to build Speculos launcher and VNC server using cmake.

    This command requires some system dependencies (ARM compiler, libvncserver
    headers...) which are documented on https://speculos.ledger.com/installation/build.html

    distutils documentation about extending the build command:
    https://docs.python.org/3.8/distutils/extending.html#integrating-new-commands
    """

    def run(self):
        super().run()


setup(
    cmdclass={
        "build_py": BuildSpeculos,
    },
)
