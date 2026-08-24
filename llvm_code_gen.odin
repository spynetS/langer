package main;
import "core:strings"
import "core:strconv"
import "core:fmt"
import llvm "./llvm-bind"

// compile .ll
// clang out.ll -o out

LLVM_Generator :: struct {
    context_ref: llvm.ContextRef,
    builder_ref: llvm.BuilderRef,
    module_ref: llvm.ModuleRef,

    // holds variables
    refs : map[string]llvm.ValueRef
}

get_tmp_name :: proc () -> cstring {
    return "tmp"
}

get_expr_type :: proc(expr: Expr) -> Type {
    #partial switch v in expr {
        case Expr_Array: panic("TODO")
        case Expr_Subscript: panic("TODO")
        case Expr_Binary: panic("TODO")
        case Expr_Unary:
        return get_expr_type(v.operand^)
        case Expr_Number: return v.type
        case Expr_Identifier: return v.type
        case Expr_String:
        // TODO should be char
        to := new(Type)
        to^ = .INT
        return Pointer({to=to})
        case Expr_Call: return v.type
    }
    panic("TODO")
}

get_llvm_type :: proc(g: ^LLVM_Generator ,type: Type) -> llvm.TypeRef {
    #partial switch v in type {
        case Basic:
        #partial switch v {
            case .INT:    return llvm.Int32TypeInContext(g.context_ref)
            case .VOID:   return llvm.VoidTypeInContext(g.context_ref)
            case .FLOAT:  return llvm.FloatTypeInContext(g.context_ref)
            case .DOUBLE: return llvm.DoubleTypeInContext(g.context_ref)
            case .STRING: return llvm.PointerTypeInContext(g.context_ref, 0)
        }
        case Pointer: return llvm.PointerTypeInContext(g.context_ref, 0)
        case Array: panic("TODO")

    }
    fmt.println(type)
    panic("TODO")
}

create_function_decl :: proc (g: ^LLVM_Generator, func: Function_Decl) -> llvm.ValueRef {
    type := get_llvm_type(g, func.type)
    arg_length := len(func.args)
    param_types := make([]llvm.TypeRef, arg_length)
    for i in 0..<arg_length  {
        arg := func.args[i]
        param_types[i] = get_llvm_type(g, arg.type)
    }

    func_type := llvm.FunctionType(type, raw_data(param_types), u32(arg_length), 0)
    
    fun :=  llvm.AddFunction(g.module_ref, fmt.ctprintf(func.name), func_type)

    // for i in 0..<arg_length  {
    //     arg := func.args[i]
    //     g.refs[arg.name] = llvm.GetParam(fun, u32(i))
    // }
    return fun
}

create_decl :: proc (g: ^LLVM_Generator, decl_u: Decl) -> llvm.ValueRef {
    switch decl in decl_u {
    case Variable_Decl:
        type := get_llvm_type(g,decl.type)

        var := llvm.BuildAlloca(g.builder_ref, type, get_tmp_name())

        g.refs[decl.name] = var

        if decl.initlizer != nil {

            val := create_expression(g, decl.initlizer)
            return llvm.BuildStore(
                g.builder_ref,
                val,
                var,
            )
        }
        return var
        
    case Function_Decl: panic("TODO")
    }
    panic("HERE")
}

create_function :: proc (g: ^LLVM_Generator, func: Function_Decl) -> llvm.ValueRef {
    func_ref := create_function_decl(g, func);
    bb_name := cstring("entry\x00")
    entry_bb := llvm.AppendBasicBlockInContext(g.context_ref, func_ref, bb_name)
    llvm.PositionBuilderAtEnd(g.builder_ref, entry_bb)
    if func.block == nil do panic("TODO")

    // create stack variables from arguments
    // This is so we get pass by value
    // we create new stack variables and copy over the argument data
    for i in 0..<len(func.args) {
        arg := func.args[i]
        param := llvm.GetParam(func_ref, u32(i))
        type := get_llvm_type(g, arg.type)
        var := llvm.BuildAlloca(g.builder_ref, type, "arg_var")

        llvm.BuildStore(g.builder_ref,
                        param,
                        var)
        
        g.refs[arg.name] = var
    }

    created_return := false
    for item in func.block.items {
        switch v in item{
        case Decl:
            create_decl(g, v);
        case Stmt:
            if _, ok := v.(Return_Stmt); ok {
                created_return = true
            }
            create_stmt(g, v);
        }
    }

    if !created_return {
        llvm.BuildRetVoid(g.builder_ref)
    }
    
    return func_ref
}

create_call :: proc(g: ^LLVM_Generator, expr: Expr_Call) -> llvm.ValueRef {
    fn_ref := llvm.GetNamedFunction(g.module_ref, fmt.ctprintf(expr.name))

    if fn_ref == nil {
        parser_panic(Expr(expr), fmt.tprintf("Could not find %s", expr.name))
    }
    fn_type := llvm.GlobalGetValueType(fn_ref)

    a_len := len(expr.args)
    llvm_args := make([]llvm.ValueRef, a_len)
    defer delete(llvm_args)
    
    for i in 0..<a_len {
        arg := expr.args[i]
        llvm_args[i] = create_expression(g, arg^)
    }
    // if return type is void we should pass empty string otherwise
    // we want to capture the return
    str := get_expr_type(expr) == Basic(.VOID) ? cstring("") : cstring("ans")

    call := llvm.BuildCall2(
        g.builder_ref,
        fn_type,
        fn_ref,
        raw_data(llvm_args),
        u32(a_len),
        str
    )

    return call
}

create_add :: proc (g: ^LLVM_Generator, left, right: Expr) -> llvm.ValueRef {
    lt := get_expr_type(left)
    rt := get_expr_type(right)


    left := create_expression(g, left)
    right := create_expression(g, right)

    if      lt == Basic(.FLOAT) || rt == Basic(.FLOAT)   do return llvm.BuildFAdd(g.builder_ref, left, right, get_tmp_name())
    else if lt == Basic(.DOUBLE) || rt == Basic(.DOUBLE) do return llvm.BuildFAdd(g.builder_ref, left, right, get_tmp_name())
    else                                                 do return llvm.BuildAdd(g.builder_ref, left, right, get_tmp_name())
}


create_sub :: proc (g: ^LLVM_Generator, left, right: Expr) -> llvm.ValueRef {
    lt := get_expr_type(left)
    rt := get_expr_type(right)


    left := create_expression(g, left)
    right := create_expression(g, right)

    if      lt == Basic(.FLOAT)  || rt == Basic(.FLOAT)  do return llvm.BuildFSub(g.builder_ref, left, right, get_tmp_name())
    else if lt == Basic(.DOUBLE) || rt == Basic(.DOUBLE) do return llvm.BuildFSub(g.builder_ref, left, right, get_tmp_name())
    else                                                 do return llvm.BuildSub(g.builder_ref, left, right, get_tmp_name())
}


create_mult :: proc (g: ^LLVM_Generator, left, right: Expr) -> llvm.ValueRef {
    lt := get_expr_type(left)
    rt := get_expr_type(right)


    left := create_expression(g, left)
    right := create_expression(g, right)

    if      lt == Basic(.FLOAT) || rt  == Basic(.FLOAT)   do return llvm.BuildFMul(g.builder_ref, left, right, get_tmp_name())
    else if lt == Basic(.DOUBLE) || rt == Basic(.DOUBLE) do return llvm.BuildFMul(g.builder_ref, left, right, get_tmp_name())
    else                                                 do return llvm.BuildMul(g.builder_ref, left, right, get_tmp_name())
}

create_div :: proc (g: ^LLVM_Generator, left, right: Expr) -> llvm.ValueRef {
    lt := get_expr_type(left)
    rt := get_expr_type(right)


    left := create_expression(g, left)
    right := create_expression(g, right)

    if      lt == Basic(.FLOAT) || rt  == Basic(.FLOAT)   do return llvm.BuildFDiv(g.builder_ref, left, right, get_tmp_name())
    else if lt == Basic(.DOUBLE) || rt == Basic(.DOUBLE) do return llvm.BuildFDiv(g.builder_ref, left, right, get_tmp_name())
    else                                                 do return llvm.BuildSDiv(g.builder_ref, left, right, get_tmp_name())
}

create_assign :: proc (g: ^LLVM_Generator, left, right: Expr) -> llvm.ValueRef {

    left_val : llvm.ValueRef = {}

    #partial switch v in left {
        case Expr_Identifier:
        ref := g.refs[v.value]
        left_val = ref
        case Expr_Unary:
        if v.operator != .UP do panic("TODO")
        t, ok := get_expr_type(v.operand^).(Pointer)
        if !ok do panic("TODO")

        ptr := create_expression(g, v.operand^);
        type := get_llvm_type(g, get_expr_type(v.operand^))
        left_val = ptr
        
        case Expr_Subscript:
        type := get_llvm_type(g, get_expr_type(v.left^))
        ptr := create_expression(g, v.left^);        
        index := create_expression(g, v.index^)

        ptrel := llvm.BuildGEP2(
            g.builder_ref,
            type,
            ptr,
                &index,
            1,
            cstring("element_ptr"),
        )

        left_val = ptrel
    }
    right_val := create_expression(g, right)

    
    return llvm.BuildStore(
        g.builder_ref,
        right_val,
        left_val
    )

    
    // fmt.println(left)
    // panic("TODO")
}

create_binary :: proc (g: ^LLVM_Generator, expr: Expr_Binary) -> llvm.ValueRef {

    #partial switch expr.op {
        case .PLUS:   return create_add(g, expr.left^, expr.right^)
        case .MINUS:  return create_sub(g, expr.left^, expr.right^)
        case .STAR:   return create_mult(g, expr.left^, expr.right^)
        case .DIVIDE: return create_div(g, expr.left^, expr.right^)
        case .EQUAL:  return create_assign(g, expr.left^, expr.right^)

    }
    panic("TODO")
}

create_number :: proc(g: ^LLVM_Generator, expr: Expr_Number) -> llvm.ValueRef {
    #partial switch t in expr.type {
    case Basic:
        #partial switch t {
            case .INT:
            val,ok := strconv.parse_int(expr.value)
            if !ok do parser_panic(expr, "Not an integer")
            return llvm.ConstInt(get_llvm_type(g,Basic(.INT)), u64(val), 0)
            case .FLOAT:
            value,_ := strings.replace(expr.value, "f", "",1)
            val,ok := strconv.parse_f32(value)
            if !ok do parser_panic(expr, "Not an float")
            return llvm.ConstReal(get_llvm_type(g,Basic(.FLOAT)), f64(val))
            case .DOUBLE:
            value,_ := strings.replace(expr.value, "d", "",1)
            val,ok := strconv.parse_f64(value)
            if !ok do parser_panic(expr, "Not an double")
            return llvm.ConstReal(get_llvm_type(g,Basic(.DOUBLE)), f64(val))

        }
    }
    panic("WRONG TYPE")
}

load_pointer :: proc (g: ^LLVM_Generator, ptr: llvm.ValueRef, type: llvm.TypeRef) -> llvm.ValueRef {
    return llvm.BuildLoad2(
        g.builder_ref,
        type,
        ptr,
        "deref_ptr"
    )
}

create_expression :: proc(g: ^LLVM_Generator, expr: Expr) -> llvm.ValueRef{
    switch v in expr{
    case Expr_Array: panic("TODO")
    case Expr_Subscript:
        type := get_llvm_type(g, get_expr_type(v.left^))
        ptr := create_expression(g, v.left^);        
        index := create_expression(g, v.index^)

        ptrel := llvm.BuildGEP2(
            g.builder_ref,
            type,
            ptr,
                &index,
            1,
            cstring("element_ptr"),
        )

        return llvm.BuildLoad2(
            g.builder_ref,
            type,
            ptrel,
            "ptrval"
        )

    case Expr_Number:
        return create_number(g, v);
    case Expr_String:
        value := strings.clone_to_cstring(strings.trim(v.value, "\""))
        return llvm.BuildGlobalStringPtr(
            g.builder_ref,
            value,
            fmt.ctprintf("str")
        )
    case Expr_Identifier:
        ref,ok := g.refs[v.value]
        if !ok do panic("TODO Could not find the variable")
        type := get_llvm_type(g, v.type)
        return llvm.BuildLoad2(g.builder_ref, type, ref, get_tmp_name())
        //panic("TODO")
    case Expr_Binary: return create_binary(g, v)
    case Expr_Call:
        return create_call(g, v);
    case Expr_Unary:
        #partial switch v.operator {
            case .UP:
            type := get_llvm_type(g, get_expr_type(v.operand^))
            ptr := create_expression(g, v.operand^);
            return load_pointer(g, ptr, type)
            case .AMPER:
            lvalue, ok := v.operand.(Expr_Identifier);
            if !ok do parser_panic(lvalue, "asd")

            return g.refs[lvalue.value]
        }
        panic("TODO")
    }
    panic("TODO")
}

create_stmt :: proc(g: ^LLVM_Generator, stmt: Stmt) -> llvm.ValueRef {
    switch v in stmt{
    case Expr:
        return create_expression(g, v)
    case Return_Stmt:
        if v.value == nil do panic("TODO VALUE NULL")
        val := create_expression(g, v.value^)
        return llvm.BuildRet(g.builder_ref, val)

    case If_Stmt:
        panic("TODO")
    case While_Stmt:
        panic("TODO")
    case Block:
        panic("TODO")
    }
    panic("TODO")
}

gen_program :: proc (g: ^LLVM_Generator, p: Program, file: string) {
    context_ref := llvm.ContextCreate()
    defer llvm.ContextDispose(context_ref)

    g.context_ref = context_ref

    mod_name := cstring("test_module\x00")
    module_ref := llvm.ModuleCreateWithNameInContext(mod_name, context_ref)
    defer llvm.DisposeModule(module_ref)
    g.module_ref = module_ref

    builder_ref := llvm.CreateBuilderInContext(context_ref)
    defer llvm.DisposeBuilder(builder_ref)
    g.builder_ref = builder_ref
    
    for func in p.functions {
        if func.extern do create_function_decl(g, func)
        else do create_function(g, func)
    }

    error_msg: cstring
    if llvm.PrintModuleToFile(module_ref, fmt.ctprintf(file), &error_msg) != 0 {
        fmt.eprintln("Failed to write module:", error_msg)
        llvm.DisposeMessage(error_msg)
    }
}
