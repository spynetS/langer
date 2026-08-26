package main;
import "core:fmt"
import "core:strings"

checker_get_func :: proc (program: Program, name: string) -> (Function_Decl, bool) {
    for func in program.functions {
        if func.name == name do return func, true
    }
    return {}, false
}

checker_get_var :: proc {
    checker_get_var_func,
    checker_get_var_block
}

checker_get_var_block :: proc (block: Block, name: string) -> (Variable_Decl, bool) {
    for items in block.items {
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

checker_get_var_func :: proc (func: Function_Decl, name: string) -> (Variable_Decl, bool) {
    if func.block == nil do return {}, false

    for arg in func.args {
        if arg.name == name {
            return arg, true
        }
    }

    return checker_get_var_block(func.block^, name)
}

expr_set_type :: proc(expr_u: ^Expr, type: Type) {
    #partial switch &expr in expr_u {
        case Expr_Subscript:
        expr.type = type
        case Expr_Number:
        expr.type = type
        case Expr_Identifier:
        expr.type = type
        case Expr_Call:
        expr.type = type
    }
}

// get_decl_name :: proc(decl: Decl) -> string {
//     switch v in decl {
//     case Variable_Decl: return v.name
//     case Function_Decl: return v.name
//     case Struct_Decl: return v.name
//     }
//     return ""

// }


// get_members :: proc(obj: Expr_MemberAccess, access_member: string) -> [dynamic]Variable_Decl {
//     members := make([dynamic]Variable_Decl)
//     obj_name : string

//     #partial switch v in obj.obj {
//     case Struct_Decl:
//         members = v.members
//         obj_name = v.name
//         case: panic("SHOULD BE")
//     }

//     return members
// }

// get_member :: proc(obj: Variable_Decl, access_member: string) -> (Variable_Decl, bool) {
//     members := make([dynamic]Variable_Decl)
//     defer delete(members)
//     obj_name : string

//     #partial switch v in obj.type {
//         case Struct_Decl:
//         members = v.members
//         obj_name = v.name
//         case: panic("SHOULD BE")
//     }


//     for i in 0..<len(members) {
//         member := members[i]
//         if member.name == access_member {
//             return member, true
//         }
//     }
//     parser_panic(obj, fmt.tprintf("'{}' has no member '{}'", obj_name, access_member))

//     return {}, false
// }



checker_get_type :: proc(program: Program, current_func: Function_Decl, expr: ^Expr) -> Type {
    if expr == nil do panic("ASD")
    switch &value in expr {
    case Expr_MemberAccess:
        //checker_get_type(program, current_func, value.obj.(Struct_Decl))
        p_t := checker_get_type(program, current_func, value.obj)

        if struc, is := p_t.(Struct_Decl); is {
            for mem in struc.members {
                if mem.name == value.member {
                    // logln("=======================")
                    // logln("here", type_to_string(mem.type))
                    // logln("=======================")
                    return mem.type
                }
            }
        }


    case Expr_Unary:
        //fmt.println(expr_to_string(value.operand^))
        p_t := checker_get_type(program, current_func, value.operand)
        // have to set the real value type
        expr_set_type(value.operand, p_t) 
        
        if value.operator == .UP && !check_type(p_t, Pointer({})) && !check_type(p_t, Array({})) {
            parser_panic(value, fmt.tprintf("Can't do %s on %s because it's not right type ({})", value.operator, expr_to_string(value.operand^), p_t))
        }
        
        switch v in p_t {
        case Pointer: return v.to^
        case Array:   return v.of^
        case Basic, Struct_Decl:
            if value.operator == .UP do parser_panic(expr^, "Can't dereferance non pointer type")
            t := new(Type)
            t^ = get_expr_type(value.operand^)
            return Pointer({to=t})
        }

    case Expr_Subscript:

        var, found := checker_get_var(current_func, value.left.value)
        if !found{
            parser_panic(value, value.left^, fmt.tprintf("Variable '{}' not found", value.left.value))
        }


        if var.initlizer == nil {
            parser_panic(value, value.left^, "Variable hasn't been initlized yet")
        }

        expr := new(Expr)
        expr^ = value.left^;
        type := checker_get_type(program, current_func, expr);
        if type == nil do panic("asd")
        free(expr)

        value.left.type = type
        checker_get_type(program, current_func, value.index) // type checking index
        sub_type : Type
        #partial switch v in type {
            case Array:
            sub_type = v.of^;
            case Pointer:
            sub_type = v.to^;
        }
        value.type = sub_type
        return sub_type

    case Expr_Identifier:
        // look in the ast for the identifer
        //func, f_func := checker_get_func(program, value.value);
        //fmt.println("looking for", value.value)
        var, f_var := checker_get_var(current_func, value.value);
        if !f_var do parser_panic(value, fmt.tprintf("Variable '%s' not found", value.value))
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
        
        if can_cast(rt, lt) {
            expr_set_type(value.right, rt)
        }
        else if !check_type(lt, rt) do parser_panic(value, fmt.tprintf("Assigment types doesnt match {} != {}", lt, rt))

        return get_expr_type(expr^)
    case Expr_Call:
        func_call, found := checker_get_func(program, value.name)
        if !found do parser_panic(value , fmt.tprintf("function %s hasn't be declared", value.name))

        value.type = func_call.type;

        if len(value.args) < len(func_call.args) {
            parser_panic(value, value.args[len(value.args)-1]^, fmt.tprintf("Argument length missmatch wanted %d got %d", len(func_call.args), len(value.args)))
        }


        for i in 0..<len(value.args) {
            if i >= len(func_call.args) {
                parser_panic(value, value.args[i]^, fmt.tprintf("Argument length missmatch wanted %d got %d", len(func_call.args), len(value.args)))
            }
            func_type := func_call.args[i].type
            call_type := checker_get_type(program, current_func, value.args[i])
            //parser_panic(value, fmt.tprintf("{} {}", func_type, call_type), level=0)
            if can_cast(call_type, func_type) {
                expr_set_type(value.args[i], func_type)
            }
            else if !check_type(func_type, call_type) {
                parser_panic(value, value.args[i]^, fmt.tprintf("Argument missmatch {} != {}", func_type, call_type))
            }
        }
        return func_call.type
    }
    //fmt.println(expr)
    panic("TODO")
}
check_type :: proc(a, b: Type) -> bool {
    if a == nil || b == nil do return false

    switch x in a {
    case Struct_Decl:
        struc, ok := a.(Struct_Decl);
        if !ok do return false
        return x.name == struc.name 
        
    case Basic:
        y, ok := b.(Basic)
        if !ok {
            return false
        }
        if x == y do return true
        // if ((x == .FLOAT && y == .INT)  || (x == .INT && y == .FLOAT)) do return true
        // if ((x == .DOUBLE && y == .INT) || (x == .INT && y == .DOUBLE)) do return true

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
            return false //check_type(x.to^, v)
        }
    }

    return false 
}

// can_cast :: proc(a, b: Type) -> bool {
//     if check_type(a, b) do return true
//     switch x in a {
//     case Basic:
//         y, ok := b.(Basic)
//         if !ok {
//             return false
//         }
//         if ((x == .FLOAT  && y == .INT) || (x == .INT && y == .FLOAT))  do return true
//         if ((x == .DOUBLE && y == .INT) || (x == .INT && y == .DOUBLE)) do return true
//         if ((x == .BYTE   && y == .INT) || (x == .INT && y == .BYTE))   do return true
//         if ((x == .BYTE   && y == .INT) || (x == .INT && y == .BYTE))   do return true
//     case Pointer:
        
//     case Array: return false;
//     }
//     return false
// }

can_cast :: proc(a, b: Type) -> bool {
    if check_type(a, b) {
        return true
    }

    switch x in a {
    case Basic:
        y, ok := b.(Basic)
        if !ok {
            return false
        }
        // Numeric conversions
        if (x == .FLOAT && y == .INT) ||
           (x == .INT   && y == .FLOAT) {
            return true
        }

        if (x == .DOUBLE && y == .INT) ||
           (x == .INT    && y == .DOUBLE) {
            return true
        }

        if (x == .BYTE && y == .INT) ||
           (x == .INT  && y == .BYTE) {
            return true
        }

    case Pointer:
        y, ok := b.(Basic)
        if !ok {
            return false
        }

        // ^BYTE -> STRING
        if y == .STRING {
            pointed_to, ok := x.to^.(Basic)
            if ok && pointed_to == .BYTE {
                return true
            }
        }

    case Array:
        return false
    case Struct_Decl:
        return false
    }

    return false
}


check_block :: proc(program: Program, func: Function_Decl, block: ^Block) {
    for &items in block.items {
        switch &item in items {
        case Decl:
            switch &decl in item {
            case Variable_Decl:
                if decl.initlizer != nil {
                    init_type := checker_get_type(program, func, decl.initlizer)
                    dec_type := decl.type
                    if can_cast(dec_type, init_type) {
                        expr_set_type(decl.initlizer, dec_type)
                    }
                    else if !check_type(dec_type, init_type) {
                        parser_panic(decl, fmt.tprintf("Variable declartion type missmatch %s != %s", type_to_string(dec_type), type_to_string(init_type)))
                    }
                }
            case Function_Decl:
                panic("Function declartion not support in function")
            case Struct_Decl:
                panic("Function declartion not support in function")

            }
        case Stmt:
            switch &stmt in item {
            case Expr:
                ans := checker_get_type(program, func, &stmt)
                logln("type", ans)
            case Return_Stmt:
                type := checker_get_type(program, func, stmt.value)
                stmt.type = type
                expr_set_type(stmt.value, type)
                if !check_type(func.type, type) {
                    if can_cast(type, func.type) {
                        stmt.type = func.type
                        expr_set_type(stmt.value, func.type)
                    }
                    else do parser_panic(stmt.value^, "Return type doesnt match function type")
                }

                
            case If_Stmt:
                t := checker_get_type(program, func, stmt.condition)
                check_block(program, func, stmt.block);
                if stmt.else_block != nil do check_block(program, func, stmt.else_block);

            case While_Stmt:
                checker_get_type(program, func, stmt.condition)
                check_block(program, func, stmt.block);
            case Block:
                check_block(program, func, &stmt)
            }
        }
    }
}


check :: proc(program: Program) {
    for &func in program.functions {
        if func.block == nil do continue

        // if func has no type we assign void to it (default)
        if func.type == nil do func.type = Basic(.VOID)
        
        // go trough function block and check all types
        check_block(program, func, func.block);
    }
}
