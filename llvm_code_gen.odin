package main;
import "core:strings"
import "core:fmt"
import llvm "./llvm-bind"

// compile .ll
// clang out.ll -o out

LLVM_Generator :: struct {
    context_ref: llvm.ContextRef,
    builder_ref: llvm.BuilderRef,
    module: llvm.ModuleRef
}

get_tmp_var :: proc () -> string {
    return "%tmp"
}

get_expr_type :: proc(expr: Expr) -> Type {
    #partial switch v in expr {
    case Expr_Integer: return .INT
    case Expr_Identifier: return v.type
        case Expr_String:
        // TODO should be char
        to := new(Type)
        to^ = .INT
        return Pointer({to=to})
    case Expr_Call: return v.type
    }
    fmt.println(expr)
    panic("TODO")
}

get_llvm_type :: proc(g: ^LLVM_Generator ,type: Type) -> llvm.TypeRef {
    #partial switch v in type {
        case Basic:
        #partial switch v {
            case .INT:   return llvm.Int32TypeInContext(g.context_ref)
            case .VOID:  return llvm.Int32TypeInContext(g.context_ref)
            case .FLOAT: return llvm.Int32TypeInContext(g.context_ref)
            case .STRING: return llvm.Int32TypeInContext(g.context_ref)
        }
        case Pointer: panic("TODO")

    }
    fmt.println(type)
    panic("TODO")
}

create_function :: proc (func: Function_Decl) {
}

create_call :: proc(g: ^LLVM_Generator, expr: Expr_Call) -> llvm.ValueRef {
    fn_ref := llvm.GetNamedFunction(g.module, fmt.ctprintf(expr.name))

    a_len := len(expr.args)
    llvm_args := make([]llvm.ValueRef, a_len)
    defer delete(llvm_args)
    
    for i in 0..<a_len {
        arg := expr.args[i]
        llvm_args[i] = create_expression(g, arg^)
    }

    return llvm.BuildCall2(
        g.builder_ref,
        llvm.GetElementType(llvm.TypeOf(fn_ref)),
        fn_ref,
        raw_data(llvm_args),
        u32(a_len),
        "call_result"
    )

    panic("TODO")
}

create_expression :: proc(g: ^LLVM_Generator, expr: Expr) -> llvm.ValueRef{
    switch v in expr{
    case Expr_Array: panic("TODO")
    case Expr_Subscript: panic("TODO")
    case Expr_Integer:
        return llvm.ConstInt(get_llvm_type(g,Basic(.INT)), 10, 0)
    case Expr_String: panic("TODO")
    case Expr_Identifier: panic("TODO")
    case Expr_Binary: panic("TODO")
    case Expr_Call:
        return create_call(g, v);
    case Expr_Unary: panic("TODO")
    }
    panic("TODO")
}

create_stmt :: proc(g: ^LLVM_Generator, stmt: Stmt) -> llvm.ValueRef {
    switch v in stmt{
    case Expr:
        return create_expression(g, v)
    case Return_Stmt:
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

gen_program :: proc (g: ^LLVM_Generator, p: Program) -> string {
    context_ref := llvm.ContextCreate()
    defer llvm.ContextDispose(context_ref)

    g.context_ref = context_ref

    mod_name := cstring("test_module\x00")
    module_ref := llvm.ModuleCreateWithNameInContext(mod_name, context_ref)
    defer llvm.DisposeModule(module_ref)
    g.module = module_ref

    builder_ref := llvm.CreateBuilderInContext(context_ref)
    defer llvm.DisposeBuilder(builder_ref)
    g.builder_ref = builder_ref
    
    for func in p.functions {

        if func.extern {
            continue
        }
        
        type := get_llvm_type(g, func.type)

        arg_length := len(func.args)
        param_types := make([]llvm.TypeRef, arg_length)
        for i in 0..<arg_length  {
            arg := func.args[i]
            param_types[i] = get_llvm_type(g, arg.type)
        }

        func_type: llvm.TypeRef;
        if arg_length == 0 {
            func_type = llvm.FunctionType(type, nil, 0, 0)
        } else {
            func_type = llvm.FunctionType(type, &param_types[0], u32(arg_length), 0)
        }

        func_name := fmt.ctprintf(func.name)
        func_ref := llvm.AddFunction(module_ref, func_name, func_type)

        bb_name := cstring("entry\x00")
        entry_bb := llvm.AppendBasicBlockInContext(context_ref, func_ref, bb_name)
        llvm.PositionBuilderAtEnd(builder_ref, entry_bb)

        if func.block == nil do panic("TODO")

        for item in func.block.items {
            switch v in item{
            case Decl:
                panic("TDOO")
            case Stmt:
                create_stmt(g, v);
            }
        }

        // param_a := llvm.GetParam(func_ref, 0)
        // param_b := llvm.GetParam(func_ref, 1)

        // tmp_name := cstring("tmp\x00")
        // sum := llvm.BuildAdd(builder_ref, param_a, param_b, tmp_name)

        // llvm.BuildRet(builder_ref, sum)

        
    }

    fmt.println("--------------------------------------------------")
    llvm.DumpModule(module_ref)
    fmt.println("--------------------------------------------------")
    return ""
}
