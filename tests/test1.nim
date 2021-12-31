# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest, tables
import simple_inject


var global_var* = initTable[string, bool]()


proc simple_change_global =
  global_var["simple"] = true

proc simple_main {.inj.} =
  discard 1 + 1

test "simple version works properly":
  global_var["simple"] = false
  check not global_var["simple"]  # value starts correctly
  simple_main()
  check not global_var["simple"]  # Nothing changes when it's not meant to
  set_inj("simple_main", simple_change_global)  # proc to check for in string, proc to call
  check not global_var["simple"]  # Change instructions, but don't modify anything
  simple_main()
  check global_var["simple"]  # Global changes now after detecting to add call


proc arg_change_global(args: varargs[pointer]) =
  if cast[ptr bool](args[0])[]:  # knowing what data type the first pointer is supposed to be
    global_var["arg"] = true


proc arg_main(do_change: bool = false) {.inj_with_args.} =
  discard not do_change


test "passing basic args works properly":
  global_var["arg"] = false
  check not global_var["arg"]  # value starts correctly
  arg_main(true)
  check not global_var["arg"]  # Nothing changes when it's not meant to
  set_inj("arg_main", arg_change_global)  # proc to check for in string, proc to call
  check not global_var["arg"]  # Change instructions, but don't modify anything
  arg_main(true)
  check global_var["arg"]  # Global changes now after detecting to add call

  global_var["arg"] = false  # test disabler
  check not global_var["arg"]
  call_normal:  # doesn't do any injections
    arg_main(true)
  check not global_var["arg"]
  arg_main(true)
  check global_var["arg"]
