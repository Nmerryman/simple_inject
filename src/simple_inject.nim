import  std/macros, std/tables

var global_str_to_proc* = initTable[string, proc ()]()


macro inj*(x: typed): untyped =
    expectKind(x, nnkProcDef)  # consider using RoutineNodes instead for all def
    let proc_name = x.name.strVal
    # x cannot be modified so I need to make a copy
    result = x.copy
    var modify = x[^1].copy
    let operation = block:  # Node I want to inject
        quote do:
            if global_str_to_proc.hasKey(`proc_name`):
                let runable = global_str_to_proc[`proc_name`]
                runable()
    
    # Check node to see how to modify it
    if x[^1].kind == nnkStmtList:
        modify.add(operation)
        result[^1] = modify
    else:
        var new_list = newStmtList(modify, operation)
        result[^1] = new_list


proc set_inj*(base: string, callable: proc ()) =
    global_str_to_proc[base] = callable
