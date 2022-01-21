# Each test should test default, a modification without activation, and then activation

import unittest, tables
import simple_inject


var global_var* = initTable[string, bool]()
enabled_proc_inj_override = true
inj_actions_override.active = true


proc catch_in {.watch.} =
  # This will only run when run main is called
  global_var["catch"] = false

proc catch_basic =
  global_var["catch"] = true

test "watch pragma with no args":
  global_var["catch"] = true
  # Inject the custom to trigger before they actual proc, but "catch" stays true because the main proc doesn't run
  enabled_proc_inj_override = true
  inj_actions_override.where = before
  inj_actions_override.pass_args = false
  inj_actions_override.run_proc = false
  inj_actions_override.active = true
  # enabled_proc_inj_override = true
  catch_in()
  set_inj("catch_in", catch_basic)
  check not global_var["catch"]
  catch_in()
  check global_var["catch"]
  enabled_proc_inj_override = true
  inj_actions_override.run_proc = true
  inj_actions_override.where = before
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
  enabled_proc_inj_override = false
  inj_actions_override.pass_args = true
  args_watched(true)
  check not global_var["catch args"]
  set_inj("args_watched", args_sent)
  args_watched(true)
  check not global_var["catch args"]
  enabled_proc_inj_override = true
  args_watched(true)
  check global_var["catch args"]


# reset everything
inj_actions_default = inj_actions_container(active: true)
inj_actions_override = inj_actions_container()
enabled_proc_inj_override = false

proc reset_all =
  simple_str_to_proc = initTable[string, proc ()]()
  arg_str_to_proc = initTable[string, proc(T: varargs[pointer])]()
  custom_inj_actions = initTable[string, inj_actions_container]()
  inj_actions_default = inj_actions_container(active: true)
  inj_actions_override = inj_actions_container()
  enabled_proc_inj_override = false
  global_var = initTable[string, bool]()


proc to_watch_basic {.watch.} =
  discard


proc call_basic =
  global_var["basic"] = true


proc to_watch_args(a: int, b: bool) {.watch.} =
  discard


proc call_args(x: varargs[pointer]) =
  global_var["args"] = false
  try:
    if cast[ptr int](x[0])[] == 0:
      global_var["args"] = true
  except:
    echo "incorrect dereference in call_args"


test "watch with defaults, no args":
  reset_all()
  check "basic" notin global_var  # sanity
  to_watch_basic()
  check "basic" notin global_var  # nothing when unconnected
  set_inj("to_watch_basic", call_basic)
  to_watch_basic()
  check "basic" in global_var  # verify connection


test "watch with defaults, args":
  reset_all()
  inj_actions_default.pass_args = true
  check "args" notin global_var  # sanity
  to_watch_args(0, true)
  check "args" notin global_var  # nothing when unconnected
  set_inj("to_watch_args", call_args)
  to_watch_args(0, true)
  check "args" in global_var  # verify connection
  check global_var["args"]  # correct data is passed


test "watch with override, no args":
  reset_all()
  check "basic" notin global_var  # sanity
  to_watch_basic()
  check "basic" notin global_var  # nothing when unconnected
  set_inj("to_watch_basic", call_basic)
  enabled_proc_inj_override = true
  inj_actions_override.active = true
  to_watch_basic()
  check "basic" in global_var  # verify connection


test "watch with override, args":
  reset_all()
  inj_actions_override.pass_args = true
  check "args" notin global_var  # sanity
  to_watch_args(0, true)
  check "args" notin global_var  # nothing when unconnected
  set_inj("to_watch_args", call_args)
  enabled_proc_inj_override = true
  inj_actions_override.active = true
  to_watch_args(0, true)
  check "args" in global_var  # verify connection
  check global_var["args"]  # correct data is passed


reset_all()

proc mod_false {.watch.} =
  global_var["mod"] = false

proc mod_true {.watch.} =
  global_var["mod"] = true

test "manual custom":
  global_var["mod"] = false  # baseline
  mod_true()
  check global_var["mod"]  # true works
  mod_false()
  check not global_var["mod"]  # false works

  # setup default settings
  set_inj("mod_false", mod_true)
  inj_actions_default.where = after
  inj_actions_default.pass_args = false
  inj_actions_default.run_proc = true
  inj_actions_default.active = true

  mod_false()
  check global_var["mod"]  # hook works by running true after

  inj_actions_default.where = before
  mod_false()
  check not global_var["mod"]  # no change when still hooked because true runs before

  custom_inj_actions["mod_false"] = inj_actions_container(where: after, run_proc: true, active: true)
  mod_false()
  check global_var["mod"]  # false gets a custom/non default hook to run true after

  custom_inj_actions.del("mod_false")
  mod_false()
  check not global_var["mod"]  # back to normal


test "temp_custom template":
  # Assuming past test settings are the same (true runs before)
  mod_false()
  check not global_var["mod"]

  temp_custom "mod_false", inj_actions_container(where: after, run_proc: true, active: true):
    mod_false()
  check global_var["mod"]

  mod_false()
  check not global_var["mod"]


