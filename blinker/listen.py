#!/usr/bin/env python

""" 
A simple Python script that listens on a SF for TestSerial messages.

TODO: check if it's exiting automatically
TODO: try to send something from the mote to see if communication is working or not
TODO: create a class that handles the content and outputs it accordingly
TODO: understand why is not actually listening but exiting quickly
"""

from BlinkMsg import *
from tinyos.message import MoteIF
from sys import argv

SERVER = "localhost"
DEF_PORT = "9001"

class Debugger(object):
    def __init__(self, port):
        # manages the mote interface
        self.mif = MoteIF.MoteIF()
        # Attach a source to it
        source_addr = "sf@%s:%s" % (SERVER, port)
        print "attaching to source %s" % source_addr
        self.source = self.mif.addSource(source_addr)

        self.mif.addListener(self, BlinkMsg)

    # Called by the MoteIF's receive thread when a new message is received
    def receive(self, src, msg):
        print "Received message: "+ str(msg)

if __name__ == "__main__":
    if len(argv) < 2:
        port = DEF_PORT
    else:
        port = argv[1]
    
    Debugger(port)

