#!/usr/bin/env python3
"""Install Speculos"""
import pathlib
from setuptools import find_packages, setup
import sys

setup(
    name="speculos",
    author="Ledger",
    author_email="hello@ledger.fr",
    version="0.1.0",
    url="https://github.com/LedgerHQ/speculos",
    python_requires=">=3.6.0",
    description="Ledger Blue and Nano S/X application emulator",
    long_description=pathlib.Path("README.md").read_text(),
    long_description_content_type="text/markdown",
    packages=find_packages(),
    install_requires=[
        "construct>=2.10.56,<3.0.0",
        "flask>=2.0.0,<3.0.0",
        "flask-restful>=0.3.8,<1.0",
        "jsonschema>=3.2.0,<4.0.0",
        "mnemonic>=0.19,<1.0",
        "pillow>=8.0.0,<9.0.0",
        "pyelftools>=0.27,<1.0",
        "pyqt5>=5.15.2,<6.0.0",
        "requests>=2.25.1,<3.0.0",
    ]
    + (["dataclasses>=0.8,<0.9"] if sys.version_info <= (3, 6) else []),
    extras_require={
        'dev': [
            'pytest',
            'pytest-cov'
        ]},
    setup_requires=["wheel"],
    entry_points={
        "console_scripts": [
            "speculos = speculos.main:main",
        ],
    },
    include_package_data=True,
)
