#!/usr/bin/env python
from tinyos.message import MoteIF
from TOSSIM import *
from sys import exit

from SerialMsg import SerialMsg

# add another class for more direct input sending
class Communicator(object):
    """ Sending messages directly to the motes """
    def __init__(self, port):
        self.mif = MoteIF.MoteIF()
        addr = "sf@localhost:%s" % port
        # whenever I create a connection like this it will hang waiting for input to send
        self.source = self.mif.addSource(addr)
        # the self argument is referring to the listener class
        # simply a class that implements the receive function
        self.seqno = 0
        self.tos = Tossim([])

    # I can inject a package directly to the radio
    def send_led_mask(self, dest, mask):
        "Creates a new message and sends it via the serial interface"
        # Where is the actual sending command done?
        msg = SerialMsg()
        # FIXME: the second field wants something that has write_packet stuff in it
        #self.mif.sendMsg(self.source, SerialSource(), msg.get_amType(), 0, msg)
        # creating and delivering a serial packet
        msg.set_dests(dest)
        msg.set_type(1)
        msg.set_instr(mask)
        msg.set_seqno(self.seqno)
        # setting up the "phisycal" packet
        pkt = self.tos.newSerialPacket()
        pkt.setData(msg.data)
        pkt.setType(msg.get_amType())
        # sending it 
        pkt.deliver(0, self.tos.time() + 10)

        print "sended message with dest %d with mask %d" % (dest, mask)
        self.seqno += 1

c = Communicator("9001")

while True:
    # exit gracefully when finished
    inp = raw_input("insert destination and led bitmask\n")
    print inp
    if 'q' in inp:
        break
    else:
        dest, mask = map(int, inp.split(" "))

    c.send_led_mask(dest, mask)

# c.send_led_mask(7, 4)
