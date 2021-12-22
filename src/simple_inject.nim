import  std/macros, std/tables
export tables

var simple_str_to_proc* = initTable[string, proc ()]()
var arg_str_to_proc* = initTable[string, proc(T: varargs[pointer])]()

# type wargs


## I want to add a pre and middle option and varying levels of complexity

macro inj*(x: typed): typed =
    expectKind(x, nnkProcDef)  # consider using RoutineNodes instead for all def
    let proc_name = x.name.strVal
    # x cannot be modified so I need to make a copy
    result = x.copy
    var modify = x[^1].copy
    let operation = block:  # Node I want to inject
        quote do:
            if simple_str_to_proc.hasKey(`proc_name`):
                let runable = simple_str_to_proc[`proc_name`]
                runable()
    
    # Check node to see how to modify it
    if x[^1].kind == nnkStmtList:
        modify.add(operation)
        result[^1] = modify
    else:
        var new_list = newStmtList(modify, operation)
        result[^1] = new_list


macro inj_with_args*(x: typed): untyped =
    expectKind(x, nnkProcDef)
    let proc_name = x.name.strVal
    # x cannot be modified so I need to make a copy
    result = x.copy 
    var modify = x[6].copy
    let operation = block:  # Node I want to inject
        quote do:
            if arg_str_to_proc.hasKey(`proc_name`):
                discard
                arg_str_to_proc[`proc_name`]()  # the modify is temporary to avoid an issue
    var appended = 1  # Because sometimes more things get appended to the end (such as result)
    # Check node to see how to modify it
    if x[6].kind == nnkStmtList:
        modify.add(operation)
        result[6] = modify
    else:
        var new_list = newStmtList(modify, operation)
        result[6] = new_list
        # if x.len == 8 and x[7].kind == nnkSym:  # if implicit return?
        #     result[6].add(bindSym("result"))
        #     result.del(7)
        #     appended = 2
    
    # Prep all the found parameters for the call
    let parameters = x[3].copy
    for a in 1 ..< parameters.len:
        for b in 0 ..< (parameters[a].len - 2):
            result[6][^appended][^1][^1][^1].add(parameters[a][b])  # very ugly manual traversal, but it should work because I'm traversing my consistent addition
    
    # Convert all found args to ptr
    for a in  1 ..< result[6][^appended][^1][^1][^1].len:
        result[6][^appended][^1][^1][^1][a] = newTree(nnkCall, bindsym("unsafeAddr"), result[6][^appended][^1][^1][^1][a])
    # result[6][^appended][^1][^1][^1].del(1, 1)  # delete the temp extra
    
    # Convert all found args to pointer
    for a in  1 ..< result[6][^appended][^1][^1][^1].len:
        result[6][^appended][^1][^1][^1][a] = newTree(nnkCall, bindsym("pointer"), result[6][^appended][^1][^1][^1][a])




proc set_inj*(base: string, callable: proc ()) =
    simple_str_to_proc[base] = callable

proc set_inj*(base: string, callable: proc (T: varargs[pointer])) =
    arg_str_to_proc[base] = callable
