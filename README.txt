This is to fix an issues I had with another project of mine and a feature I was trying (but probably failing) to ask about.

TODO:
clean up code
add an easier dereferencer (consider wargs)
add tests
add the last version which allows the injection proc to take in current extra arguments  (I have decide to forgo this because I can just more easily implimentit in my callback)


annoyances:
needing to know about how the backticks work
needed to export tables because the other file doesn't know about .[]
ptr and pointer are different
how to pass table[string, seq[pointer]] to proc(a: vararg[pointer]) in a macro

questions:
is cast[ptr A] and cast[ref A] the same