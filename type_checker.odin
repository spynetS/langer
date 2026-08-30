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
        case Expr_Unary:
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

        switch y in b {
        case Pointer:
            if pointed_to, ok1 := y.to^.(Basic); ok1 && pointed_to == .BYTE {
                return a, true
            }
        case Basic:
            break;
        case Array, Struct_Decl:
            return {}, false
        }

        // ^BYTE -> STRING
        // if y == .STRING {
        //     if x.to == nil do panic("")
        //     pointed_to, ok := x.to^.(Basic)
        //     if ok && pointed_to == .BYTE {
        //         return a, true
        //     }
        // }

        if pointed_to, ok1 := x.to^.(Basic); ok1 && pointed_to == .BYTE {
            return b, true
        }
  
        
        
    case Array:
        return {}, false
    case Struct_Decl:
        return {}, false
    }

    return {}, false
}

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
    // if m, is := expr.obj.(Expr_MemberAccess); is {
    //     // we continue look
    //     logln("Parent was member access")
    //     type := check_memberaccess(t, &m);
    //     is1:bool;
    //     struc, is1 = type.(Struct_Decl)
    //     if !is1 do panic("TODO ISNT STRUC")
    // }
    // if m, is := expr.obj.(Expr_Subscript); is {
    //     // we continue look
    //     logln("Parent was subscript")
    //     type := check_subscript(t, &m);
    //     is1:bool;
    //     struc, is1 = type.(Struct_Decl)
    //     if !is1 do panic("TODO ISNT STRUC")
    // }
    
    type := checker_get_type(t, expr.obj);
    is1:bool;
    struc, is1 = type.(Struct_Decl)
    if !is1 {
        if ptr, is := type.(Pointer); is && ptr.to != nil {
            struc, is = ptr.to.(Struct_Decl);
            if !is do panic("TODO ISNT STRUC")
        }
        else {
            fmt.println(type)
            panic("TODO ISNT STRUC")
        }
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
            if ptr, is := var.type.(Pointer); is && ptr.to != nil {
                struc, is = ptr.to.(Struct_Decl)
                if !is {
                    parser_panic(expr^, expr.obj^, fmt.tprintf("Object is not type struct, it is {}", type_to_string(var.type)))
                    parser_panic(var, fmt.tprintf("Declared here", type_to_string(var.type)))
                }
            }
            else {
                parser_panic(expr^, expr.obj^, fmt.tprintf("Object is not type struct, it is {}", type_to_string(var.type)))
                parser_panic(var, fmt.tprintf("Declared here", type_to_string(var.type)))
            }
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
    if arr, is := lt.(Array); is {
        if arr.of == nil do panic("HERE")
        return arr.of^
    }



    parser_panic(expr^, fmt.tprintf("Cant preform subscript for type '{}'", type_to_string(lt)))

    panic("TODO")
}

checker_get_unary :: proc(t: ^SymbolTable, expr: ^Expr_Unary) -> Type {
    #partial switch expr.operator {
        case .UP:
        t := checker_get_type(t, expr.operand);
        if ptr, ok := t.(Pointer); ok {
            if ptr.to == nil do panic("PTR IS NIL?s")
            expr_set_type(cast(^Expr)expr, ptr.to^)
            return ptr.to^;
        }
        else do panic("ASD")
        case .AMPER: panic("TODO")
    }

    panic("TODO")
}

checker_get_type :: proc(t: ^SymbolTable, expr: ^Expr) -> Type {
    if expr == nil do panic("Checker_get type expr is nil")
    switch &v in expr {
    case Expr_MemberAccess: return check_memberaccess(t, &v);
    case Expr_Array: panic("TODO")
    case Expr_Subscript:  return check_subscript(t, &v);
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
    case Expr_Unary:      return checker_get_unary(t, &v);
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
