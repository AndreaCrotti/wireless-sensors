#!/usr/bin/env python

import sys
import time
from TOSSIM import *

# node with ID0 sends command
t = Tossim([])
n = t.getNode(32)
n.bootAtTime(45654)

t.addChannel("Boot", sys.stdout)
t.addChannel("BlinkC", sys.stdout)

t.runNextEvent()
