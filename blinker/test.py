#!/usr/bin/env python
"""
python script to test if some
of the algorithms are working as expected

TODO: use standard testing stuff instead
"""
import sys
import unittest
from packet import *
from gen_network import bin_tree
from simulation import *

MAX_CYCLES = 10
DIM = 4
simpletopo = ((0,1), (0,2), (1,2))

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

# functional style testing or object oriented testing looks cleaner?
class TestSimulation(unittest.TestCase):
    def __init__(self, topology):
        self.topology = topology

    def setUp(self):
        pass

    def tearDown(self):
        # in the teardown phase we can delete everything maybe
        pass


def _test_generic(topo, dbg_channels, toadd, torem, var_triples, max_cycles, verbose=False):
    from itertools import count
    sim = Simulation(SERIAL_PORT, dbg_channels, test=True)
    sim.make_given_topology(topo)
    sim.setup_noise("noise.txt")
    sim.start(batch=True)
    if verbose:
        print sim.topology

    sim.run_some_events()
    for r in torem:
        sim.remove_connection(*r)

    for a in toadd:
        sim.add_connection(*a)

    # continues to cycle and return True only when all the conditions are fulfilled
    for n in count():
        print n
        if n == max_cycles:
            return False
        sim.run_some_events()
        if verbose:
            for n,var,_ in var_triples:
                print n, var, sim.get_variable(n, var)

        if all(sim.get_variable(n, var) == val for n,var,val in var_triples):
            return True

def test_big_binary_tree():
    "Testing a big binary tree generated"
    topo = list(bin_tree(DIM))
    triples = []
    # the parent of every node is just given by the inverse
    # we can generate the conditions to verify pretty easily
    for x, y in topo:
        triples.append((y, "EasyRoutingP.parent", x))

    for x in range(2**DIM - 1):
        triples.append((x, "EasyRoutingP.HOP_COUNTS",[255, 1, 2, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]))

    assert(_test_generic(topo, ("Routing",), [], [], var_triples=triples, max_cycles=MAX_CYCLES))

def test_routing_deletion():
    # FIXME: failing and not stopping at MAX_CYCLES for some reasons
    triples = ((2, "EasyRoutingP.parent", 1),
               (2, "EasyRoutingP.HOP_COUNTS", [255, 1, 2, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]),
               (1, "EasyRoutingP.parent", 0))

    # number of cycles could be computed, here we have to wait to be sure at least
    # 2 * total full timeout
    # we could also access to the enums in the code
    assert(_test_generic(simpletopo, ("Routing",), [], [(0,2)], var_triples=triples, max_cycles=MAX_CYCLES, verbose=True))
    print "deletion worked correctly"


def test_root_moving_away():
    # with a simple topology move the root away and then put it back
    # see also what happens while the root is not present
    
    # first remove all the link to root_node and then add them back
    sim = Simulation(SERIAL_PORT, ("BlinkC","Routing"), test=True)
    sim.make_given_topology(simpletopo)
    sim.setup_noise("noise.txt")
    sim.start(batch=True)
    
    sim.topology.remove_connection(0, 2)
    sim.topology.remove_connection(0, 1)
    # looks if they're looping
    for n in range(10):
        sim.print_var_nodes("EasyRoutingP.HOP_COUNTS")
        sim.run_some_events()
    # print now after some events run
    print sim.topology
    sim.print_var_nodes("EasyRoutingP.HOP_COUNTS")
    
    sim.topology.add_connection(0, 1)
    for n in range(10):
        sim.run_some_events()

    # we could also now try to send some sensing packets around

    print sim.topology
    sim.print_var_nodes("EasyRoutingP.HOP_COUNTS")

def test_neigbour_discovery():
    # make a full grid of 5 nodes and check that they're all neighbours
    # FIXME: also failing now
    topo = []
    dim = 5
    for x in range(dim):
        for y in range(x+1, dim):
            topo.append((x, y))
    triples = []
    for x in range(dim):
        triples.append((x, "EasyRoutingP.neighbours", 2**dim  - 1 - (1 << x)))
    assert(_test_generic(topo, (), [], [], var_triples=triples, max_cycles=MAX_CYCLES))

def test_leds():
    sim = Simulation(SERIAL_PORT, ("BlinkC","Routing"), test=True)
    sim.make_given_topology(simpletopo)
    sim.setup_noise("noise.txt")
    sim.start(batch=True)
    print sim.topology

    led = 63
    sim.run_some_events()
    sim.send_packet(turn_leds_all_nodes((0,1,2), led))
    assert(sim.check_vars_all_nodes("BlinkC.ledMask", led))

def test_network_overloading():
    # find some way to poison the radio network and see if everything is still working
    pass




TESTS = (test_leds, test_neigbour_discovery, test_routing_deletion, test_big_binary_tree)

# if __name__ == '__main__':
#     for t in TESTS:
#         try:
#             print "startin test %s" % str(t)
#             t()
#         except AssertionError:
#             print "test %s failed!!!\n\n\n" % str(t)
#         else:
#             print "test %s succedeed\n\n\n" % str(t)
