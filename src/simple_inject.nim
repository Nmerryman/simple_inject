import  std/macros, std/tables
export tables

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
var inj_actions_default* = inj_actions_container(active: true)
var inj_actions_override* = inj_actions_container()
var enabled_proc_inj_override* = false  # TODO global rn, want to make it proc specific later


# TODO wargs


## I want to add a pre and middle option and varying levels of complexity

macro inj*(x: typed): typed =
    expectKind(x, nnkProcDef)  # consider using RoutineNodes instead for all def
    let proc_name = x.name.strVal
    # x cannot be modified so I need to make a copy
    result = x.copy
    var modify = x[^1].copy
    let operation = block:  # Node I want to inject
        quote do:
            if simple_str_to_proc.hasKey(`proc_name`) and enabled_proc_inj_override:
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
            if arg_str_to_proc.hasKey(`proc_name`) and enabled_proc_inj_override:
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


template gen_inj_block(container: inj_actions_container, loc: inj_location, pass: bool, proc_trans: typed): untyped =
    quote do:
        if `container`.active and `container`.where == `loc` and not (`pass` xor `container`.pass_args) and `proc_trans`.hasKey(`proc_name`):
            `proc_trans`[`proc_name`]()


template inj_block_wrapper(container: Table[string, inj_actions_container], loc: inj_location, pass: bool, proc_trans: typed, testing: string): untyped =
    # Adds priority context
    # TODO consider changing this to a proc
    # FIXME properly propigate inj_actions_override, inj_actions_default calls, correctly add custom_inj_actions and prob fix injecting the preped args again
    quote do:
        if enabled_proc_inj_override:
            if inj_actions_override.active and inj_actions_override.where == `loc` and not (`pass` xor inj_actions_override.pass_args) and `proc_trans`.hasKey(`proc_name`):
                `proc_trans`[`proc_name`]()
        elif `proc_name` in `container`:
            if `container`.hasKey(`proc_name`) and `container`[`proc_name`].active and `container`[`proc_name`].where == `loc` and not (`pass` xor `container`[`proc_name`].pass_args) and `proc_trans`.hasKey(`proc_name`):
                `proc_trans`[`proc_name`]()
        else:
            if inj_actions_default.active and inj_actions_default.where == `loc` and not (`pass` xor inj_actions_default.pass_args) and `proc_trans`.hasKey(`proc_name`):
                `proc_trans`[`proc_name`]()


macro watch*(x: typed): typed =
    x.expectKind(nnkProcDef)
    result = x.copy
    let proc_name = x.name.strVal
    var meat = x[6].copy
    # prep all paths
    # TODO remove the debug strings here
    var pre_inj_basic = inj_block_wrapper(custom_inj_actions, before, false, simple_str_to_proc, "pre_basic")
    var post_inj_basic = inj_block_wrapper(custom_inj_actions, after, false, simple_str_to_proc, "post_basic")
    var pre_inj_arg = inj_block_wrapper(custom_inj_actions, before, true, arg_str_to_proc, "pre_arg")
    var post_inj_arg = inj_block_wrapper(custom_inj_actions, after, true, arg_str_to_proc, "post_arg")
    

    # extract, prep, and inject the parameters
    var parameters: seq[NimNode]
    for a in 1 ..< result[3].len:
        for b in 0 ..< (result[3][a].len - 2):
            parameters.add(result[3][a][b])
    
    var preped_params: seq[NimNode]
    for a in parameters:
        preped_params.add(newCall("pointer", newCall("unsafeaddr", a)))
    
    for a in preped_params:
        pre_inj_arg[0][1][0][0][1][0].add(a)
        pre_inj_arg[1][1][0][0][1][0].add(a)
        pre_inj_arg[2][0][0][0][1][0].add(a)
        post_inj_arg[0][1][0][0][1][0].add(a)
        post_inj_arg[1][1][0][0][1][0].add(a)
        post_inj_arg[2][0][0][0][1][0].add(a)
    

    # prep the meat
    if meat.kind != nnkStmtList:
        meat = newStmtList(meat.copy)
    
    # add run check to meat
    let active_check = quote do:
        if (simple_str_to_proc.hasKey(`proc_name`) or arg_str_to_proc.hasKey(`proc_name`)):
            if enabled_proc_inj_override:
                inj_actions_override.run_proc
            elif custom_inj_actions.hasKey(`proc_name`):
                custom_inj_actions[`proc_name`].run_proc
            else:
                inj_actions_default.run_proc
        else:
            true
            
    var wraped_meat = newStmtList(newIfStmt((active_check, meat)))

    # insert the injections
    wraped_meat.insert(0, pre_inj_arg)
    wraped_meat.insert(1, pre_inj_basic)
    wraped_meat.add(post_inj_arg, post_inj_basic)
    
    result[6] = wraped_meat
    

macro call_normal*(x: untyped): untyped =
    quote do:
        enabled_proc_inj_override = false
        `x`
        enabled_proc_inj_override = true



proc set_inj*(base: string, callable: proc ()) =
    simple_str_to_proc[base] = callable

proc set_inj*(base: string, callable: proc (T: varargs[pointer])) =
    arg_str_to_proc[base] = callable
