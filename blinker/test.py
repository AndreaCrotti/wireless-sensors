#!/usr/bin/env python
"""
python script to test if some
of the algorithms are working as expected
"""

import sys
from simulation import *
from gen_network import bin_tree

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

# check somehow if the topology is working fine automatically
# for a binary tree we should always get the same thing
# try to add and remove some connections also
def make_tree(high):
    tree_parents = {}
    for x in range(1, (2 ** high) - 1):
        tree_parents[x] = (x-1) / 2
    return tree_parents

def test_routing_deletion():
    """
    Start with a simple topology, remove one connection
    and then see if the parent and the hop count is set correctly
    """
    sim = Simulation(SERIAL_PORT, ("Routing", ))
    topo = ((0,1), (0,2), (1,2))
    # when removing 0-2 I should get 1 as new parent for 1
    sim.make_given_topology(topo)
    sim.setup_noise("noise.txt")
    sim.start(batch=True)
    
    sim.run_some_events()
    sim.remove_connection(0, 2)
    # check when parent is outside
    while True:
        # FIXME: 0 actually sees that 2 is not a neighbour but 2 doesn't now
        if (sim.get_variable(2, "EasyRoutingP.parent") == 1):
            break
        sim.run_some_events()
    
    assert(sim.get_variable(2, "EasyRoutingP.parent") == 1)
    assert(sim.get_variable(2, "EasyRoutingP.HOP_COUNTS")[2] == 2)
    assert(sim.get_variable(1, "EasyRoutingP.parent") == 0)
    assert(sim.get_variable(1, "EasyRoutingP.HOP_COUNTS")[2] == 2)

test_routing_deletion()
