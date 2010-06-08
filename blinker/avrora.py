#!/usr/bin/env python
"""
Do all the operations needed for testing with avrora.
Unfortunately it only works with mica2/micaz
"""

import subprocess
import sys
import os
import optparse

CMD = "java avrora.Main"

# first check if everything is there, then get the options
