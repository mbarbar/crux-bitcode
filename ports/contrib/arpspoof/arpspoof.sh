#!/bin/sh
PYVER=$(python3 -V | grep -Po '\d\.\d')
python3 /usr/lib/python${PYVER}/site-packages/arpspoof/arpspoof.py
