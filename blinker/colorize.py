#!/usr/bin/env python
# colorize.py 
import sys 

# use a list instead to cycle in it better
colors = {
    "black": '30',
    "darkred": '31',
    "darkgreen": '32',
    "brown": '33',
    "darkblue": '34',
    "purple": '35', 
    "teal": '36', 
    "lightgray": '37',
    "darkgray": '30;01',
    "red": '31;01' ,
    "green": '32;01', 
    "yellow": '33;01', 
    "blue": '34;01' ,
    "fuchsia": '35;01' ,
    "turquoise": '36;01', 
    "white": '37;01',
    "disable": ''
    }

def setcolor(s, color): 
    return '\x1b[%sm%s\x1b[00m' % (color, s) 

def main():
    prefix = sys.argv[1] 
    color_name = sys.argv[2] 
    color = colors[color_name]
    while True:
        try:
            line = sys.stdin.readline()
            if not(line):
                break

            line = line.replace("DEBUG ", "")
            line = "%s:: %s" % (prefix, line)
            sys.stdout.write(setcolor(line, color)) 

        except KeyboardInterrupt:
            # just don't care about them
            continue

if __name__ == '__main__': 
    main() 
