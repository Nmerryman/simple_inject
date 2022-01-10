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


proc catch_in {.watch.} =
  # This will only run when run main is called
  global_var["catch"] = false

proc catch_basic =
  global_var["catch"] = true

test "watch pragma with no args":
  global_var["catch"] = false
  # Inject the custom to trigger before they actual proc, but "catch" stays true because the main proc doesn't run
  inj_actions.where = before
  inj_actions.pass_args = false
  inj_actions.run_proc = false
  inj_actions.active = true
  set_inj("catch_in", catch_basic)
  catch_in()
  check global_var["catch"]
  inj_actions.run_proc = true
  catch_in()
  check not global_var["catch"]


proc args_watched(val: bool) {.watch.} =
  discard not val

proc args_sent(vals: varargs[pointer]) =
  let given = cast[ptr bool](vals[0])[]
  if given:
    global_var["catch args"] = true

test "watch pragma with args":
  global_var["catch args"] = false
  inj_actions.where = after
  inj_actions.pass_args = true
  inj_actions.run_proc = true
  inj_actions.active = false
  args_watched(true)
  check not global_var["catch args"]
  set_inj("args_watched", args_sent)
  args_watched(true)
  check not global_var["catch args"]
  inj_actions.active = true
  args_watched(true)
  check global_var["catch args"]

  

