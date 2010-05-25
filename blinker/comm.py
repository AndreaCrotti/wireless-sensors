#!/usr/bin/env python
from tinyos.message import MoteIF
from TOSSIM import *

from SerialMsg import SerialMsg

# # add another class for more direct input sending
class Communicator(object):
    """ Sending messages directly to the motes """
    def __init__(self, port):
        # the self argument is referring to the listener class
        # simply a class that implements the receive function
        self.mif = MoteIF.MoteIF()
        self.mif.addSource("sf@localhost:%s" % port)
        self.seqno = 0
        self.tos = Tossim([])

    # I can inject a package directly to the radio
    def send_led_mask(self, dest, mask):
        "Creates a new message and sends it via the serial interface"
        # creating and delivering a serial packet
        msg = SerialMsg()
        msg.set_dests(dest)
        msg.set_type(1)
        msg.set_instr(mask)
        msg.set_seqno(self.seqno)
        # setting up the "phisycal" packet
        pkt = self.tos.newSerialPacket()
        pkt.setData(msg.data)
        pkt.setType(msg.get_amType())
        pkt.setDestination(0)
        # sending it 
        pkt.deliver(0, self.tos.time())# + 10)

        print "sended message with dest %d with mask %d and seqno %d\n" % (dest, mask, self.seqno)
        self.seqno += 1

c = Communicator(9001)

while True:
    # exit gracefully when finished
    inp = raw_input("insert destination and led bitmask\n")
    # use a try here instead
    dest, mask = map(int, inp.split(" "))
    c.send_led_mask(dest, mask)
