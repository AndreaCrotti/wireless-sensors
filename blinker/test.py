#!/usr/bin/env python
"""
python script to test if some
of the algorithms are working as expected
"""

import sys
from simulation import *
from gen_network import bin_tree

#############################
# def getIdFromBM(bitmask): #
#     counter = 0           #
#     bitmask >>= 1         #
#     while (bitmask != 0): #
#         bitmask >>= 1     #
#         counter += 1      #
#                           #
#     return counter        #
#############################

def updateLedMask(ledmask, led):
    return ledmask & (~led >> 3) ^ led

# We can also maybe
# - send a packet
# - start a listener that waits for the answer
# - see if everything is correct or not


# when doing automated testing the DEBUG output should be ignored completely
# Test
# 1. leds setting
# 2. data sensing
# For
# 1. different topologies
# 2. random values
# more...

class InputChecker(object):
    def __init__(self, fp):
        self.fp = fp

    def write(self, message):
        self.fp.write(message)


# MASKS = (0x9, 0x8, 0x12, 0x10, 0x24, 0x20)
MASKS = (0x9, 0x12, 0x24)

# FIXME: of course not working, not setting right things
def test_led_setting():
    sim.start(batch=True)
    nodes = sorted(sim.nodes.keys())
    for ledmask in MASKS:
        print "sending ledmask %d" % ledmask
        sim.send_packet(turn_leds_all_nodes(nodes, ledmask))
        # make sure we give enough time
        sim.run_some_events()
        assert(sim.check_vars_nodes(nodes, "BlinkC.ledMask", ledmask))

def count_led():
    sim.start(batch=True)
    nodes = sorted(sim.nodes.keys())
    num = sim.count_events_needed(turn_leds_all_nodes(nodes, 1), "BlinkC.ledMask", 1)
    print "needed %d events" % num

# check somehow if the topology is working fine automatically
# for a binary tree we should always get the same thing
# try to add and remove some connections also
def make_tree(high):
    tree_parents = {}
    for x in range(1, (2 ** high) - 1):
        tree_parents[x] = (x-1) / 2
    return tree_parents

def test_bin_tree(dim):
    tree = make_tree(dim)
    sim.setup_noise("noise.txt")
    sim.make_bin_tree(dim)
    sim.start(batch=True)
    sim.run_some_events()
    nodes = sorted(sim.nodes.keys())
    for n in sorted(sim.nodes.keys()[1:]):
        parent = sim.get_variable(n, "EasyRoutingP.parent")
        ## FIXME: not working now with 3 for example, check why
        print n, parent
        assert(parent == tree[n])

def test_routing_deletion():
    sim = Simulation(SERIAL_PORT, [])
    topo = ((0,1), (0,2), (1,2))
    # when removing 0-2 I should get 1 as new parent for 1
    sim.setup_noise("noise.txt")
    sim.make_given_topology(topo)
    print sim.topology
    sim.start(batch=True)
    sim.run_some_events()
    sim.run_some_events()
    sim.run_some_events()
    
    sim.print_var_motes("EasyRoutingP.parent")
    sim.print_var_motes("EasyRoutingP.HOP_COUNTS")
    sim.run_some_events()
    sim.run_some_events()
    sim.run_some_events()
    sim.run_some_events()
    sim.run_some_events()
    sim.run_some_events()
    sim.run_some_events()
    sim.remove_connection(0, 2)
    print sim.topology
    # check when parent is outside
    sim.print_var_motes("EasyRoutingP.parent")
    sim.print_var_motes("EasyRoutingP.HOP_COUNTS")

test_routing_deletion()
