## Simulate pressing a gui button that changes what it does between presses 
import ../src/simple_inject

proc second  # fix second not being defined yet

# Allow changing what call gets made when the onButton proc is called
proc first =
    echo "Changing callback: first -> second"
    set_inj("onButtonPress", second)

proc second =
    echo "Changing callback: second -> first"
    set_inj("onButtonPress", first)


proc onButtonPress {.watch.} =  # Normaly set callback proc
    echo "button pressed"


proc main =
    set_inj("onButtonPress", first)  # Starting setting
    inj_actions_default.where = after

    const presses = 10
    for a in 0 ..< presses:
        onButtonPress()  # gui button pressed and proc called


if isMainModule:
    main()
