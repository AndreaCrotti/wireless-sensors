"""
Some nice menu creation facilitites
"""
import rlcompleter
import readline

# FIXME: use an ordered structure instead
class MenuMaker(object):
    def __init__(self, options, style="num"):
        "Pass a dictionary in the form Message:Function_to_call"
        self.style = style
        self.options = options
        self.menu = dict(enumerate(self.options.keys()))

    def __str__(self):
        # only enumerate the things
        menu_str = ["%d) %s" % (x, y) for x, y in self.menu.items()]
        return "\n" + "\n".join(menu_str) + "\n"

    # maybe one other thing like __call__ would be better
    def call_option(self):
        complete_on(self.menu.keys())
        print str(self)
        ch = input()
        # calling the right function, should work anywhere given the correct scope
        self.options[self.menu[ch]]()


# check if this is really working
def complete_on(completion_list):
    "Activate tab completion list over the list given"
    readline.parse_and_bind("tab: complete")
    c = rlcompleter.Completer(dict(zip(completion_list, completion_list)))
    readline.set_completer(c.complete)
