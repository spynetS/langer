package main;
import "core:fmt"
import "core:strings"

checker_get_func :: proc (program: Program, name: string) -> (Function_Decl, bool) {
    for func in program.functions {
        if func.name == name do return func, true
    }
    return {}, false
}

checker_get_var :: proc (func: Function_Decl, name: string) -> (Variable_Decl, bool) {
    if func.block == nil do return {}, false
    for items in func.block.items {
        #partial switch item in items {
        case Decl:
            #partial switch decl in item{
                case Variable_Decl:
                if decl.name == name {
                    return decl, true
                }
            }
        }
    }

    return {}, false
}
checker_get_type :: proc(program: Program, current_func: Function_Decl, expr: Expr) -> string {
    #partial switch value in expr {
        case Expr_Subscript:
        return strings.to_lower(checker_get_type(program, current_func, value.left^))
        case Expr_Identifier:
        // look in the ast for the identifer
        //func, f_func := checker_get_func(program, value.value);
        var, f_var := checker_get_var(current_func, value.value);
        if !f_var do panic(fmt.tprintf("Variable %s not found", value.value))

        return var.type

        case Expr_Array:
        return checker_get_type(program, current_func, value.values[0]^)
        case Expr_Integer: return "int"
        case Expr_String:  return "string"
        case Expr_Binary:  return checker_get_type(program, current_func, value.left^)
        case Expr_Call:
        for func in program.functions {
            if value.name == func.name {
                return func.type
            }
        }
    }
    panic("TODO")
}

check :: proc(program: Program) {
    for func in program.functions {
        if func.block == nil do continue

        for items in func.block.items {
            switch item in items {
            case Decl:
                switch decl in item {
                case Variable_Decl:
                    break
                case Function_Decl:
                    panic("Function declartion not support in function")
                }
            case Stmt:
                switch stmt in item {
                case Expr:
                    switch expr in stmt {
                    case Expr_Call:
                        func_call, found := checker_get_func(program, expr.name)
                        if !found do panic(fmt.tprintf("function %s hasn't be declared", expr.name))

                        for i in 0..<len(func_call.args) {
                            func_type := strings.to_lower(func_call.args[i].type)
                            call_type := strings.to_lower(checker_get_type(program, func, expr.args[i]^))
                            if func_type != call_type {
                                panic(fmt.tprintf("Argument missmatch %s != %s", func_type, call_type))
                            }

                        }

                    case Expr_Integer:
                        panic("todo")
                    case Expr_Identifier:
                        panic("todo")
                    case Expr_Array:
                        panic("todo")
                    case Expr_Binary:
                        if expr.op == .EQUAL {
                            left_type := checker_get_type(program, func, expr.left^)
                            right_type := checker_get_type(program, func, expr.right^)

                            if left_type != right_type do panic (fmt.tprintf("Assigment types doesnt match %s != %s", left_type, right_type))
                        }
                        else do panic("TODO")

                    case Expr_String:
                        panic("todo")
                    case Expr_Subscript:
                        panic("todo")
                    }
                case Return_Stmt:
                    if func.type != checker_get_type(program, func, stmt.value^) {
                        panic("Return type doesnt match function type")
                    }
                    
                case If_Stmt:
                    panic("todo")
                case While_Stmt:
                    //panic("todo")
                case Block:
                    panic("todo")
                }
            }
        }
        
    }
}
