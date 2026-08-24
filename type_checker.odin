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

    for arg in func.args {
        if arg.name == name {
            return arg, true
        }
    }

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
checker_get_type :: proc(program: Program, current_func: Function_Decl, expr: ^Expr) -> Type {
    switch &value in expr {
    case Expr_Unary:
        ex := new(Expr)
        defer free(ex)
        ex^ = cast(Expr)value.operand
        p_t := checker_get_type(program, current_func, ex)
        // have to set the real value type
        value.operand.type = p_t

        switch v in p_t {
        case Pointer: return v.to^
        case Array: return v.of^
        case Basic:
            if value.operator == .UP do parser_panic(expr^, "Can't dereferance non pointer type")
            t := new(Type)
            t^ = value.operand.type
            return Pointer({to=t})

        }

    case Expr_Subscript:
        type := checker_get_type(program, current_func, cast(^Expr)value.left)
        #partial switch v in type {
            case Array:
            return v.of^;
            case Pointer:
            return v.to^;
        }
        parser_panic(expr^, "Variable not an array")
        panic("NOT AN ARRAY?!")
    case Expr_Identifier:
        // look in the ast for the identifer
        //func, f_func := checker_get_func(program, value.value);
        fmt.println("looking for", value.value)
        var, f_var := checker_get_var(current_func, value.value);
        if !f_var do parser_panic(value, fmt.tprintf("Variable %s not found", value.value))
        value.type = var.type // We set it here also
        return var.type
    case Expr_Array:
        //return checker_get_type(program, current_func, value.values[0]^)
        //return fmt.tprintf("%s_arr", checker_get_type(program, current_func, value.values[n0]^))
        val_type := new(Type) // FIXME MEMORY
        val_type^ = checker_get_type(program, current_func, value.values[0])
        return Array({of=val_type})

    case Expr_Number: return value.type
    case Expr_String:  return .STRING
    case Expr_Binary:
        lt := checker_get_type(program, current_func, value.left)
        rt := checker_get_type(program, current_func, value.right)
        if !check_type(lt, rt) do panic("TODO")
        return lt
    case Expr_Call:
        for func in program.functions {
            if value.name == func.name {
                return func.type
            }
        }
        parser_panic(expr^, "function not found")
        
    }
    fmt.println(expr)
    panic("TODO")
}
check_type :: proc(a, b: Type) -> bool {
    if a == nil || b == nil do return false

    switch x in a {
    case Basic:
        y, ok := b.(Basic)
        if !ok {
            return false
        }
        if x == y do return true
        if ((x == .FLOAT && y == .INT) || (x == .INT && y == .FLOAT)) do return true
        if ((x == .DOUBLE && y == .INT) || (x == .INT && y == .DOUBLE)) do return true

    case Array:
        y, ok := b.(Array)
        if !ok {
            return false
        }
        return check_type(x.of^, y.of^)

    case Pointer:
        #partial switch v in b {
            case Array:
            if v.of == nil do return true // FIXME
            return check_type(x.to^, v.of^)
            case Pointer:
            if v.to == nil do return true // FIXME
            return check_type(x.to^, v.to^)
            case Basic:
            return check_type(x.to^, v)
        }
    }

    return false 
}

check :: proc(program: Program) {
    for &func in program.functions {
        if func.block == nil do continue

        // if func has no type we assign void to it (default)
        if func.type == nil do func.type = Basic(.VOID)

        // go trough function block and check all types
        for &items in func.block.items {
            switch &item in items {
            case Decl:
                switch &decl in item {
                case Variable_Decl:
                    init_type := checker_get_type(program, func, &decl.initlizer)
                    dec_type := decl.type
                    if !check_type(dec_type,init_type) {
                        parser_panic(decl, fmt.tprintf("Variable declartion type missmatch %s != %s", dec_type, init_type))
                    }
                case Function_Decl:
                    panic("Function declartion not support in function")
                }
            case Stmt:
                switch &stmt in item {
                case Expr:
                    switch &expr in stmt {
                    case Expr_Call:
                        func_call, found := checker_get_func(program, expr.name)
                        if !found do parser_panic(expr , fmt.tprintf("function %s hasn't be declared", expr.name))

                        expr.type = func_call.type;

                        for i in 0..<len(expr.args) {
                            if i >= len(func_call.args) {
                                parser_panic(expr, expr.args[i]^, fmt.tprintf("Argument length missmatch %d != %d", len(func_call.args), len(expr.args)))
                            }
                            func_type := func_call.args[i].type
                            call_type := checker_get_type(program, func, expr.args[i])
                            if !check_type(func_type, call_type) {
                                parser_panic(expr, expr.args[i]^, fmt.tprintf("Argument missmatch %s != %s", func_type, call_type))
                            }
                        }

                    case Expr_Unary:
                        t := new(Expr)
                        defer free(t)

                        t^ = expr.operand

                        type := checker_get_type(program, func, t)
                        expr.operand.type = type
                        if !check_type(type, Pointer({})) && !check_type(type, Array({})) {
                            parser_panic(expr, fmt.tprintf("Can't do %s on %s because it's not right type (%s)", expr.operator, expr.operand.value, type))
                        }

                    case Expr_Number:
                        panic("todo")
                    case Expr_Identifier:
                        panic("todo")
                    case Expr_Array:
                        panic("todo")
                    case Expr_Binary:
                        if expr.op == .EQUAL {
                            left_type := checker_get_type(program, func, expr.left)
                            right_type := checker_get_type(program, func, expr.right)

                            if !check_type(right_type, left_type) do parser_panic(expr, fmt.tprintf("Assigment types doesnt match %s != %s", left_type, right_type))
                        }
                        else do panic("TODO")

                    case Expr_String:
                        panic("todo")
                    case Expr_Subscript:
                        panic("todo")
                    }
                case Return_Stmt:
                    type := checker_get_type(program, func, stmt.value)
                    if func.type != type {
                        parser_panic(stmt.value^, "Return type doesnt match function type")
                    }
                    stmt.type = type

                case If_Stmt:
                    panic("todo")
                case While_Stmt:
                    fmt.println("TODO check while")
                    //                    panic("todo")
                case Block:
                    panic("todo")
                }
            }
        }
        
    }
}
