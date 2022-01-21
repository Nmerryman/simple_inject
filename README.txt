This is to fix an issues I had with another project of mine and a feature I was trying (but probably failing) to ask about.

This module allows injecting procs at run time from other modules.


TODO:
add an easier dereferencer/better encapsulation (consider wargs)


annoyances (Things I needed to try figure out via extra searching):
needing to know about how the backticks work
needed to export tables because the other file doesn't know about .[]
ptr and pointer are different
how to pass table[string, seq[pointer]] to proc(a: vararg[pointer]) in a macro
