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
