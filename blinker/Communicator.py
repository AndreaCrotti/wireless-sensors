#!/usr/bin/env python
from tinyos.message import MoteIF
from TOSSIM import *

from BlinkMsg import BlinkMsg

# add another class for more direct input sending
class Communicator(object):
    """ Sending messages directly to the motes """
    def __init__(self, port):
        self.mif = MoteIF.MoteIF()
        addr = "sf@localhost:%s" % port
        self.mif.addSource(addr)
        # the self argument is referring to the listener class
        # simply a class that implements the receive function
        self.mif.addListener(self, BlinkMsg)
        self.seq_no = 0

        # use pkt deliver instead

    # why should it be here the listener if I only want to send something?
    def receive(self, src, msg):
        print "Received message from %s: %s" % (str(msg), str(src))

    # I can inject a package directly to the radio
    def send_led_mask(self, dest, mask):
        # Where is the actual sending command done?
        t = Tossim([])
        msg = BlinkMsg()
        msg.set_dests(7);
        pkt = t.newPacket();
        pkt.setData(msg.data)
        pkt.setType(msg.get_amType())
        pkt.setDestination(0)

        pkt.deliver(7, t.time() + 3)
        self.seq_no += 1


c = Communicator("9001")
c.send_led_mask(7, 4)
