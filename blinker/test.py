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

# general skeleton
# - inital topology
# - to add
# - to remove
# - variables to check
# check if it's generic enough or how it could be modified

def test_generic(topo, dbg_channels, toadd, torem, var_triples, cycles):
    sim = Simulation(SERIAL_PORT, dbg_channels)
    sim.make_given_topology(topo)
    sim.setup_noise("noise.txt")
    sim.start(batch=True)
    
    sim.run_some_events()
    for r in torem:
        sim.remove_connection(*r)

    for a in toadd:
        sim.add_connection(*a)
    
    for n in range(cycles):
        sim.run_some_events()
        
    for node, var, value in var_triples:
        assert(sim.get_variable(node, var) == value)

def test_routing_deletion():
    topo = ((0,1), (0,2), (1,2))
    triples = ((2, "EasyRoutingP.parent", 1),
               (2, "EasyRoutingP.HOP_COUNTS", [255, 1, 2, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]),
               (1, "EasyRoutingP.parent", 0))

    # number of cycles could be computed, here we have to wait to be sure at least
    # 2 * total full timeout
    # we could also access to the enums in the code
    test_generic(topo, ("Routing",), [], [(0,2)], var_triples=triples, cycles=10)

test_routing_deletion()
