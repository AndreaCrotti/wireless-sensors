#!/usr/bin/env python

"""
Usage
for vals in rand_graph(10, 4):
    print vals
"""

import random

DB_RANGE = (-60, -50)

def rand_graph(num, conn):
    "Creates a random graph with n elments"
    for x in range(0, num):
        for y in range(x+1, num):
            if random.random() * conn > 1:
                val = float(random.randrange(*DB_RANGE))
                yield(x, y, val)
                yield(y, x, val + random.randrange(3))

# FIXME: if MAX_NODES not multiple of 4 something strange could happen
def bin_tree(dim):
    "Generates a binary tree connection"
    for x in range((2 ** dim) - 1):
        yield (x, x * 2 + 1)
        yield (x, (x+1) * 2)


def network_to_hops_parents(topo):
    """
    Given a topology as a list of couples return the a dictionary
    with the minimal hops and the parent
    """
    parents, hops, grid = {}, {}, {}
    for x, y in topo:
        if x in grid:
            grid[x].append(y)
        else:
            grid[x] = []

        if y in grid:
            grid[y].append(x)
        else:
            grid[y] = []

    # we build the structure starting from node 0
    for x in grid:
        parents[x] = None
        hops[x] = 255

    idx = 0
    parents[idx] = 0
    hops[idx] = 0
    # just use a BFS algorithm here

def sim_txt_to_png(topo_file):
    topo = []
    for line in open(topo_file):
        vals = line.split()
        topo.append((int(vals[0]), int(vals[1])))

    topology_to_png(topo, topo_file.split(".")[0])

def topology_to_png(topology, filename):
    try:
        import pydot
    except ImportError:
        print "you need to install pydot for this"
        return
    
    p = pydot.Dot()
    for x,y in topology:
        p.add_edge(pydot.Edge(str(x), str(y)))
    
    f = filename + ".png"
    print "writing out to %s" % f
    p.write_png(f)
    

