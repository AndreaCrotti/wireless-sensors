#!/usr/bin/env python
"""
python script to test if some
of the algorithms are working as expected
"""
import sys
from simulation import *
from gen_network import bin_tree

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

def _test_generic(topo, dbg_channels, toadd, torem, var_triples, max_cycles, verbose=False):
    from itertools import count
    sim = Simulation(SERIAL_PORT, dbg_channels, test=True)
    sim.make_given_topology(topo)
    sim.setup_noise("noise.txt")
    sim.start(batch=True)
    
    sim.run_some_events()
    for r in torem:
        sim.remove_connection(*r)

    for a in toadd:
        sim.add_connection(*a)
    
    # continues to cycle and return True only when all the conditions are fulfilled
    for n in count():
        if n == max_cycles:
            return False
        sim.run_some_events()
        if verbose:
            for n,var,_ in var_triples:
                print n, var, sim.get_variable(n, var)

        if all(sim.get_variable(n, var) == val for n,var,val in var_triples):
            return True

def test_big_binary_tree(dim):
    "Testing a big binary tree generated"
    topo = list(bin_tree(dim))
    print topo
    triples = []
    # the parent of every node is just given by the inverse
    # we can generate the conditions to verify pretty easily
    for x, y in topo:
        triples.append((y, "EasyRoutingP.parent", x))
    
    assert(_test_generic(topo, ("Routing",), [], [], var_triples=triples, max_cycles=100))
    # now we can remove node 1 for example and relink 3-4
    toadd = [(0, 3), (0,4)]
    toremove = [(1, 3), (1, 4)]
    triples = ((3, "EasyRoutingP.parent", 0),
               (4, "EasyRoutingP.parent", 0))
    assert(_test_generic(topo, ("Routing",), [], [], var_triples=triples, max_cycles=100, verbose=True))

def test_routing_deletion():
    topo = ((0,1), (0,2), (1,2))
    triples = ((2, "EasyRoutingP.parent", 1),
               (2, "EasyRoutingP.HOP_COUNTS", [255, 1, 2, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]),
               (1, "EasyRoutingP.parent", 0))

    # number of cycles could be computed, here we have to wait to be sure at least
    # 2 * total full timeout
    # we could also access to the enums in the code
    assert(_test_generic(topo, ("Routing",), [], [(0,2)], var_triples=triples, max_cycles=100, verbose=True))
    print "deletion worked correctly"

test_routing_deletion()
# test_big_binary_tree(5)
