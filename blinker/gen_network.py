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
        val = float(random.randrange(*DB_RANGE))
        yield (x, x * 2 + 1, val)
        yield (x, (x+1) * 2, val)

# TODO: use a decorator for this usage instead
def write_topology(topo_maker, out_file):
    for vals in topo_maker():
        pass
