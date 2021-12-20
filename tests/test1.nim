# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import simple_inject

test "can add":
  check `+`(5, 5) == 10

var global_var* = 1

proc change_global =
  global_var = 2

proc basic_proc {.inj.} =
  discard 1 + 1

test "Correct starting values":
  check global_var == 1

test "Global variable changes when it should":
  basic_proc()
  check global_var == 1
  set_inj("basic_proc", change_global)
  check global_var == 1
  basic_proc()
  check global_var == 2
