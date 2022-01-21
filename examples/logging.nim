## The idea is that the logging can be easily added or removed without needing to impact the way the main program works

import ../src/simple_inject
import random


# --- Custom stuff (could be in a different file) ---
var flip_log: array[2, int]  # will store the logging data


proc logSide(data: varargs[pointer]) =
    let side = cast[ptr int](data[0])[] # I know the input for the first arg is an int
    flip_log[side] += 1  # I cheat knowing that side will only ever be 0 or 1


proc printLog =
    # Just to print the log cleanly for my sake, not part of the example
    echo "heads: " & $flip_log[0] & ", tails: " & $flip_log[1]


# --- Main program ---
proc getSideName(side: int): string {.watch.} =
    # Do some calculations of the input and work like a normal proc
    if side == 0:
        result = "heads"
    else:
        result = "tails"


proc main =
    set_inj("getSideName", logSide)  # proc to call when getSideName gets called
    inj_actions_default.pass_args = true  # we care about the args be default
    
    # just flips coins
    const coinFlips = 10
    var side: int
    for a in 0 ..< coinFlips:
        side = rand(0 .. 1)
        echo getSideName(side)
    


when isMainModule:
    main()
    printLog()  # to show the logging is correct


