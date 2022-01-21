This is to fix an issues I had with another project of mine and a feature I was trying (but probably failing) to ask about.

This module allows injecting procs at run time from other modules.

Objects to care about:
```nim
type inj_location* = enum
    before, after
type inj_actions_container* = object
    where*: inj_location
    pass_args*: bool
    run_proc*: bool
    active*: bool

var simple_str_to_proc* = initTable[string, proc ()]()
var arg_str_to_proc* = initTable[string, proc(T: varargs[pointer])]()
var custom_inj_actions* = initTable[string, inj_actions_container]()
var inj_actions_default* = inj_actions_container(active: true, run_proc: true)
var inj_actions_override* = inj_actions_container()
var enabled_proc_inj_override* = false
```

simple_str_to_proc and arg_str_to_proc are if you really want to do custom manipulations, otherwise simply use `set_inj()` to set up connection.
custom_inj_actions, inj_actions_default, inj_actions_override, and enabled_proc_inj_override are used for manipulating how the injectionn is done. inj_actions_override has highest prority when enabled_proc_inj_override is enabled. Then comes custom_inj_actions and if nothing is set the default is used.


Simply add a `{.watch.}` pragma to any proc definition and then run `set_inj("proc_name_of_watched", callback_proc)` to inject the callback anytime the watched one is called. Check out the examples or test to see how it can be done. 


Limitations:
    recursive procs


TODO:
add an easier dereferencer/better encapsulation (consider wargs)


annoyances (Things I needed to try figure out via extra searching):
needing to know about how the backticks work
needed to export tables because the other file doesn't know about .[]
ptr and pointer are different
how to pass table[string, seq[pointer]] to proc(a: vararg[pointer]) in a macro
