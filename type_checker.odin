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
    logln("trying to set type to be", type_to_string(type), "for", expr_to_string(expr_u^),"which has", get_expr_type(expr_u^))
    if expr_u == nil do panic("asd")
    #partial switch &expr in expr_u {
        case Expr_Subscript:
        expr.type = type
        case Expr_Number:
        expr.type = type
        case Expr_Identifier:
        expr.type = type
        case Expr_Call:
        expr.type = type
        case Expr_MemberAccess:
        expr.type = type
        case Expr_Binary:
        expr_set_type(expr.left, type)
        expr_set_type(expr.right, type)
    }
    logln(expr_to_string(expr_u^),"has now", type_to_string(get_expr_type(expr_u^)))
}



can_cast :: proc(a, b: Type) -> (Type, bool) {
    logln("can cast?", type_to_string(a), type_to_string(b))
    if check_type(a, b) {
        return a, true
    }

    switch x in a {
    case Basic:

        y, ok := b.(Basic)
        if !ok {
            return {}, false
        }
        // Numeric conversions
        if (x == .FLOAT && y == .INT) ||
           (x == .INT   && y == .FLOAT) {
               return Basic(.FLOAT),true
        }

        if (x == .DOUBLE && y == .INT) ||
           (x == .INT    && y == .DOUBLE) {
               return Basic(.DOUBLE),true
        }

        if (x == .DOUBLE && y == .FLOAT) ||
           (x == .FLOAT    && y == .DOUBLE) {
               return Basic(.DOUBLE),true
        }


        if (x == .BYTE && y == .INT) ||
           (x == .INT  && y == .BYTE) {
               return Basic(.BYTE),true
        }

    case Pointer:
        y, ok := b.(Basic)
        if !ok {
            return {}, false
        }
        // ^BYTE -> STRING
        if y == .STRING {
            if x.to == nil do panic("")
            pointed_to, ok := x.to^.(Basic)
            if ok && pointed_to == .BYTE {
                return a, true
            }
        }

    case Array:
        return {}, false
    case Struct_Decl:
        return {}, false
    }

    return {}, false
}

// checker_get_type :: proc(t: ^SymbolTable, expr: ^Expr) -> Type {
//     if expr == nil do panic("ASD")
//     switch &value in expr {
//     case Expr_MemberAccess:
//         //checker_get_type(program, current_func, value.obj.(Struct_Decl))
//         p_t := checker_get_type(t,value.obj)

//         if struc, is := p_t.(Struct_Decl); is {
//             for mem in struc.members {
//                 if mem.name == value.member {
//                     // logln("=======================")
//                     // logln("here", type_to_string(mem.type))
//                     // logln("=======================")
//                     return mem.type
//                 }
//             }
//         }


//     case Expr_Unary:
//         //fmt.println(expr_to_string(value.operand^))
//         p_t := checker_get_type(t, value.operand)
//         // have to set the real value type
//         expr_set_type(value.operand, p_t) 
        
//         if value.operator == .UP && !check_type(p_t, Pointer({})) && !check_type(p_t, Array({})) {
//             parser_panic(value, fmt.tprintf("Can't do %s on %s because it's not right type ({})", value.operator, expr_to_string(value.operand^), p_t))
//         }
        
//         switch v in p_t {
//         case Pointer: return v.to^
//         case Array:   return v.of^
//         case Basic, Struct_Decl:
//             if value.operator == .UP do parser_panic(expr^, "Can't dereferance non pointer type")
//             t := new(Type)
//             t^ = get_expr_type(value.operand^)
//             return Pointer({to=t})
//         }

//     case Expr_Subscript:

//         var, found := checker_get_var(current_func, value.left.value)
//         if !found{
//             parser_panic(value, value.left^, fmt.tprintf("Variable '{}' not found", value.left.value))
//         }


//         if var.initlizer == nil {
//             parser_panic(value, value.left^, "Variable hasn't been initlized yet")
//         }

//         expr := new(Expr)
//         expr^ = value.left^;
//         type := checker_get_type(t, expr);
//         if type == nil do panic("asd")
//         free(expr)

//         value.left.type = type
//         checker_get_type(t, value.index) // type checking index
//         sub_type : Type
//         #partial switch v in type {
//             case Array:
//             sub_type = v.of^;
//             case Pointer:
//             sub_type = v.to^;
//         }
//         value.type = sub_type
//         return sub_type

//     case Expr_Identifier:
//         // look in the ast for the identifer
//         //func, f_func := checker_get_func(program, value.value);
//         //fmt.println("looking for", value.value)
//         var, f_var := checker_get_var(current_func, value.value);
//         if !f_var do parser_panic(value, fmt.tprintf("Variable '%s' not found", value.value))
//         value.type = var.type // We set it here also
//         return var.type
//     case Expr_Array:
//         //return checker_get_type(t, value.values[0]^)
//         //return fmt.tprintf("%s_arr", checker_get_type(t, value.values[n0]^))
//         val_type := new(Type) // FIXME MEMORY
//         val_type^ = checker_get_type(t, value.values[0])
//         return Array({of=val_type})

//     case Expr_Number: return value.type
//     case Expr_String:  return .STRING
//     case Expr_Binary:
//         lt := checker_get_type(t, value.left)
//         rt := checker_get_type(t, value.right)

//         if type, can := can_cast(rt, lt); can {
//             expr_set_type(value.right, type)
//             expr_set_type(value.left, type)
//             return type
//         }
//         else if !check_type(lt, rt) do parser_panic(value, fmt.tprintf("Assigment types doesnt match {} != {}", lt, rt))

//         return get_expr_type(expr^)
//     case Expr_Call:
//         func_call, found := checker_get_func(program, value.name)
//         if !found do parser_panic(value , fmt.tprintf("function %s hasn't be declared", value.name))

//         value.type = func_call.type;

//         if len(value.args) < len(func_call.args) {
//             parser_panic(value, value.args[len(value.args)-1]^, fmt.tprintf("Argument length missmatch wanted %d got %d", len(func_call.args), len(value.args)))
//         }


//         for i in 0..<len(value.args) {
//             if i >= len(func_call.args) {
//                 parser_panic(value, value.args[i]^, fmt.tprintf("Argument length missmatch wanted %d got %d", len(func_call.args), len(value.args)))
//             }
//             func_type := func_call.args[i].type
//             call_type := checker_get_type(t,value.args[i])
//             //parser_panic(value, fmt.tprintf("{} {}", func_type, call_type), level=0)
//             if type, can := can_cast(call_type, func_type); can {
//                 expr_set_type(value.args[i], func_type)
//             }
//             else if !check_type(func_type, call_type) {
//                 parser_panic(value, value.args[i]^, fmt.tprintf("Argument missmatch {} != {}", func_type, call_type))
//             }
//         }
//         return func_call.type
//     }
//     //fmt.println(expr)
//     panic("TODO")
// }

checker_get_identifier_type :: proc(t: ^SymbolTable, expr: ^Expr_Identifier) -> Type {
    logln("CHECKING IDENTIDER", expr_to_string(expr^))
    if symb, found := symbol_table_loopup(t, expr.value); found {
        expr.type = symb.type
        return symb.type
    }
    else {
        parser_panic(expr^, "not found")
    }
    panic("SHOULNT BE HERE")
}

checker_get_binary_type :: proc(t: ^SymbolTable, expr: ^Expr_Binary) -> Type {
    logln("CHECKING BINARY", expr_to_string(expr^))
    lt := checker_get_type(t, expr.left)
    rt := checker_get_type(t, expr.right)
    print_expr(expr.left^)
    print_expr(expr.right^)
    logln(lt, rt)
    if t, can := can_cast(lt, rt); can {
        expr_set_type(expr.left, t)
        expr_set_type(expr.right, t)
        return t
    }
    else do parser_panic(expr^, fmt.tprintf("Can't preform '{}' between types {} {}",expr.op, type_to_string(lt), type_to_string(rt)))
    panic("TODO")
}


checker_get_call_type :: proc(t: ^SymbolTable, expr: ^Expr_Call) -> Type {
    logln("CHECKING caller", expr_to_string(expr^))
    // we want to return the function decl type
    // and also check the argument types
    if symbol, found := symbol_table_loopup(t, expr.name); found {
        func, ok := symbol.node.(Function_Decl)
        if !ok do panic("ITS NOT A FUNC")
        
        for i in 0..<len(func.args) {
            if i >= len(expr.args) do parser_panic(expr^, "Call length is to short")
            at := checker_get_type(t, expr.args[i])
            if t, can := can_cast(at, func.args[i].type); can {
                expr_set_type(expr.args[i], t)
            }
            else do parser_panic(expr^, fmt.tprintf("TODO"))

        }
        if symbol.type == nil do panic("SHOULD HAVE TYPE")
        expr_set_type(cast(^Expr)expr, symbol.type)
        return symbol.type
    }

    panic("TODO")
}

check_memberaccess :: proc (t: ^SymbolTable, expr: ^Expr_MemberAccess) -> Type {
    logln("CHECKING member", expr_to_string(expr^))
    struc: Struct_Decl;
    // we look for the first definition by
    // going backards in the member access tree
    // looking at each obj (parent)
    if m, is := expr.obj.(Expr_MemberAccess); is {
        // we continue look
        logln("Parent was member access")
        type := check_memberaccess(t, &m);
        is1:bool;
        struc, is1 = type.(Struct_Decl)
        if !is1 do panic("TODO ISNT STRUC")

    }
    if m, is := expr.obj.(Expr_Identifier); is {

        // we found a identifer, could be variable

        symbol, found := symbol_table_loopup(t, m.value)
        if !found do panic("TODO COULDNT FIND VARIABLE")
        
        var, is := symbol.node.(Variable_Decl);
        if !is {
            //fmt.println(symbol.node)
            panic("TODO ISNT VAR")
        }
        is1:bool;
        struc, is1 = var.type.(Struct_Decl)
        if !is1 {
            parser_panic(expr^, expr.obj^, fmt.tprintf("Object is not type struct, it is {}", type_to_string(var.type)))
            parser_panic(var, fmt.tprintf("Declared here", type_to_string(var.type)))
        }
    }

    expr_set_type(expr.obj, struc);

    // retrieve the member
    for m in struc.members {
        //fmt.println("is", m.name , "==", expr.member)
        if m.name == expr.member {
            expr.type = m.type;
            //fmt.println(expr_to_string(expr^))
            //fmt.println("type of expr is", type_to_string(expr.type))
            return expr.type
        }
    }
    panic("TODO")
}

check_subscript :: proc(t: ^SymbolTable, expr: ^Expr_Subscript) -> Type {
    lt := checker_get_type(t, expr.left)
    rt := checker_get_type(t, expr.index)

    if t, can := can_cast(rt, Basic(.INT)); can {
        expr_set_type(expr.index, Basic(.INT));
    }
    else {
        parser_panic(expr^, expr.index^, "Index must be integer")
    }

    if ptr, is := lt.(Pointer); is {
        if ptr.to == nil do panic("HERE")
        return ptr.to^
    }


    parser_panic(expr^, fmt.tprintf("Cant preform subscript for type '{}'", type_to_string(lt)))

    panic("TODO")
}

checker_get_type :: proc(t: ^SymbolTable, expr: ^Expr) -> Type {
    if expr == nil do panic("Checker_get type expr is nil")
    switch &v in expr {
    case Expr_MemberAccess: return check_memberaccess(t, &v);
    case Expr_Array: panic("TODO")
    case Expr_Subscript: return check_subscript(t, &v);
    case Expr_Number:
        logln("CHECKING NUMBER", v.value)
        if v.type == nil do panic("NIIIL")
        else do return v.type
    case Expr_String:
        to := new(Type)
        to^ = Basic(.BYTE)
        return Pointer({to=to})
    case Expr_Identifier: return checker_get_identifier_type(t, &v)
    case Expr_Binary:     return checker_get_binary_type(t, &v);
    case Expr_Call:       return checker_get_call_type(t, &v);
    case Expr_Unary: panic("TODO")
    }
    fmt.println(expr)
    panic("TODO")
}

check_type :: proc(a, b: Type) -> bool {
    if a == nil || b == nil do return false

    switch x in a {
    case Struct_Decl:
        struc, ok := b.(Struct_Decl);
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



check_block :: proc(program: Program, func: Function_Decl, block: ^Block, t: ^SymbolTable) {
    for &items in block.items {
        
        switch &item in items {
            
        case Decl:
            
            switch &decl in item {
                
            case Variable_Decl:
                if decl.initlizer != nil {
                    it := checker_get_type(t, decl.initlizer)
                    if type, can := can_cast(decl.type, it); can {
                        expr_set_type(decl.initlizer, decl.type)
                    }
                    else if !check_type(decl.type, it) {
                        parser_panic(decl, fmt.tprintf("Variable declartion type missmatch %s != %s", type_to_string(decl.type), type_to_string(it)))
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
                ans := checker_get_type(t, &stmt)
                print_stmt(stmt);
                
            case Return_Stmt:
                type := checker_get_type(t, stmt.value)
                stmt.type = type
                expr_set_type(stmt.value, type)
                if !check_type(func.type, type) {
                    if type, can := can_cast(type, func.type); can {
                        stmt.type = func.type
                        expr_set_type(stmt.value, func.type)
                    }
                    else do parser_panic(stmt.value^, "Return type doesnt match function type")
                }

                
            case If_Stmt:
                panic("TODO")

                // check_block(program, func, stmt.block, t);
                // if stmt.else_block != nil do check_block(program, func, stmt.else_block, t);

            case While_Stmt:
                panic("TODO")
                // checker_get_type(t, stmt.condition)
                // check_block(program, func, stmt.block, t);
                
            case Block:
                check_block(program, func, &stmt, t)
            }
            
        }
    }
}


check :: proc(program: Program, t: ^SymbolTable) {
    for &func in program.functions {
        if func.block == nil do continue

        // if func has no type we assign void to it (default)
        if func.type == nil do func.type = Basic(.VOID)

        func_t,found := symbol_table_loopup(t, func.name)
        if !found do panic("FUNC NOT FOUND!??!?!")
        
        // go trough function block and check all types
        check_block(program, func, func.block, func_t.scope);
    }
}
