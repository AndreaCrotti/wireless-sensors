#!/usr/bin/env python
# -*- encoding: utf-8 -*-

"""
This script is used to receive and print
out debug messages that we get from the serial forwarder
port
"""

import sys

from DebugMsg import *
import tinyos.packet
import tinyos.message

class Debugger():
    """Extending the DebugMsg class to parse the debugging output"""
    def __init__(self):
        

print "everything is imported"
