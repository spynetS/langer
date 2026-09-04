package main;
import "core:fmt"
import "core:strings"

/*
checker_get_func :: proc (package_: Package, name: string) -> (Function_Decl, bool) {
    for func in package_.functions {
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
*/
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
    if a == nil && b != nil do return b, true
    
    if check_type(a, b) {
        return a, true
    }

    switch x in a {
    case StructType: panic("TODO")
    case NamedType:
        // if ptr, ok := b.(Pointer); ok &&
        //     ptr.to != nil &&
        //     check_type(ptr.to^, Basic(.BYTE)) {
        //         return a, true
        // }
        return {}, false;
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
        case StructType: panic("TODO")
        case NamedType: panic("TODO")
        case Pointer:
            if pointed_to, ok1 := y.to^.(Basic); ok1 && pointed_to == .BYTE {
                return a, true
            }
        case Basic:
            break;
        case Array:
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
    }

    return {}, false
}

checker_replace_named_type :: proc(t: ^SymbolTable, type: Type) -> Type {
    type := type
    if ptr, is := type.(Pointer); is {
        if ptr.to == nil do panic("AHH")
        type = checker_replace_named_type(t, ptr.to^)
    }

    nt, is := type.(NamedType);
    if !is do return type

    if t_symb, found := symbol_table_lookup_path(t, nt.path); found {
        struc, is := t_symb.node.(Struct_Decl)
        if !is do panic("ADD PARSER PANIC")

        return StructType {
            path=nt.path,
            members = struc.members
        }
    }
    return nt
}

checker_get_identifier_type :: proc(t: ^SymbolTable, expr: ^Expr_Identifier) -> (Type, ^SymbolTable) {
    logln("CHECKING IDENTIDER", expr_to_string(expr^))
    if symb, found := symbol_table_lookup(t, expr.value); found {
        // if it is a named type
        // we should look up that type and replace
        // the identifers type with that type
        symb.type = checker_replace_named_type(t, symb.type)
        expr.type = symb.type
        return symb.type, t
    }
    else {
        parser_panic(expr^, "not found")
    }
    panic("SHOULNT BE HERE")
}

checker_get_binary_type :: proc(t: ^SymbolTable, expr: ^Expr_Binary) -> (Type, ^SymbolTable) {
    logln("CHECKING BINARY", expr_to_string(expr^))
    lt,scope := checker_get_type(t, expr.left)
    rt,_     := checker_get_type(t, expr.right)
    print_expr(expr.left^)
    print_expr(expr.right^)
    logln(lt, rt)
    if t, can := can_cast(lt, rt); can {
        expr_set_type(expr.left, t)
        expr_set_type(expr.right, t)
        return t, scope
    }
    else do parser_panic(expr^, fmt.tprintf("Can't preform '{}' between types {} {}",expr.op, type_to_string(lt), type_to_string(rt)))
    panic("TODO")
}


checker_get_call_type :: proc(t: ^SymbolTable, expr: ^Expr_Call) -> (Type, ^SymbolTable) {
    logln("CHECKING caller", expr_to_string(expr.name^))

    // we want to return the function decl type
    // and also check the argument types
    if symbol, found := symbol_table_lookup(t, expr.name); found {
        func, ok := symbol.node.(Function_Decl)
        if !ok do panic("ITS NOT A FUNC")
        
        for i in 0..<len(func.args) {
            if i >= len(expr.args) do parser_panic(expr^, "Call length is to short")
            at,scope := checker_get_type(t, expr.args[i])
            if t, can := can_cast(at, func.args[i].type); can {
                logln("casting args")
                expr_set_type(expr.args[i], t)
            }
            else do parser_panic(expr^, fmt.tprintf("TODO"))

        }
        if symbol.type == nil do panic("SHOULD HAVE TYPE")
        logln("casting function call to")
        symbol.type = checker_replace_named_type(t, symbol.type)
        expr_set_type(cast(^Expr)expr, symbol.type)
        return symbol.type, symbol.scope
    }
    else if !found {
        parser_panic(expr^, "Not found")
    }
    panic("TODO")
}

// alfred.data.age -> int
// alfred.data -> person.Data
// alfred -> person.Person 

checker_dereferance :: proc(t: Type) -> Type {
    if ptr, is := t.(Pointer); is {
        if ptr.to == nil do panic("AHH")
        return ptr.to^
    }
    else do return t
}
/*
checker_memberaccess :: proc (t: ^SymbolTable, expr: ^Expr_MemberAccess) -> (Type, ^SymbolTable) {
    scope := t
    parent_type : Type
    fmt.println("checking parent", expr_to_string(expr.obj^))
    parent_type, scope = checker_get_type(t, expr.obj)
    fmt.println("done checking parent")
    fmt.println("now checking for member", expr.member)
    
    fmt.println("=====")
    fmt.println(expr_to_string(expr^), parent_type)
    fmt.println("=====")

    d_ptr := checker_dereferance(parent_type)

    struc : Struct_Decl

    if nt, is := d_ptr.(NamedType); is {
        symbol, found := symbol_table_lookup_path(scope, nt.value);
        scope = symbol.scope
        ok: bool
        struc, ok = symbol.node.(Struct_Decl)
        if !ok {
            fmt.println(symbol.node)
            panic("TODO")
        }
        fmt.println("FOUND struc", struc.name)
    }
    else do panic("TODO")

    fmt.println("looking for ", expr.member, "in ", struc.members[:])
    for m in struc.members {
        if m.name == expr.member {
            expr.type = m.type
            fmt.println("found member of type", m.type)
            return m.type, scope
        }
    }
    
    fmt.println("no member found, returning", parent_type)
    return parent_type, scope
}
*/
checker_subscript :: proc(t: ^SymbolTable, expr: ^Expr_Subscript) -> (Type, ^SymbolTable) {
    lt,scope := checker_get_type(t, expr.left)
    rt,_ := checker_get_type(t, expr.index)

    if t, can := can_cast(rt, Basic(.INT)); can {
        expr_set_type(expr.index, Basic(.INT));
    }
    else {
        parser_panic(expr^, expr.index^, "Index must be integer")
    }

    if ptr, is := lt.(Pointer); is {
        if ptr.to == nil do panic("HERE")
        return ptr.to^, scope
    }
    if arr, is := lt.(Array); is {
        if arr.of == nil do panic("HERE")
        return arr.of^, scope
    }



    parser_panic(expr^, fmt.tprintf("Cant preform subscript for type '{}'", type_to_string(lt)))

    panic("TODO")
}

checker_get_unary :: proc(t: ^SymbolTable, expr: ^Expr_Unary) -> (Type, ^SymbolTable) {
    #partial switch expr.operator {
        case .UP:
        t,scope := checker_get_type(t, expr.operand);
        if ptr, ok := t.(Pointer); ok {
            if ptr.to == nil do panic("PTR IS NIL?s")
            expr_set_type(cast(^Expr)expr, ptr.to^)
            return ptr.to^, scope
        }
        else {
              fmt.println(t)
              panic("TODO")
        }
        case .AMPER: panic("TODO")
    }

    panic("TODO")
}



checker_get_number :: proc(t: ^SymbolTable, v: ^Expr_Number) -> (Type, ^SymbolTable) { 
    logln("CHECKING NUMBER", v.value)
    if v.type == nil do panic("NIIIL")
    else do return v.type, t
}

checker_get_string :: proc(t: ^SymbolTable, v: ^Expr_String) -> (Type, ^SymbolTable) {
    to := new(Type)
    to^ = Basic(.BYTE)
    return Pointer({to=to}), t
}


// alfred.person.data
checker_memberaccess :: proc (t: ^SymbolTable, expr: ^Expr_MemberAccess) -> (Type, ^SymbolTable) {
    logln("Checking memberaccess", expr_to_string(expr^))
    // retrieve the type of our "parent"
    type, scope := checker_get_type(t, expr.obj)
    type = checker_dereferance(type)
    
    // check for type error
    path : [dynamic]string
    #partial switch v in type {
        case NamedType:
        path = v.path

        type = checker_replace_named_type(t, v)

        case StructType:
        path = v.path
        case:
        parser_panic(expr^, expr.obj^, fmt.tprintf("Can't do memberacees on this type '{}'", type_to_string(type)))
    } 
    

    // find the definition of the type
    // and get the type of the member 
    if symbol, found := symbol_table_lookup_path(t, path); found {
        #partial switch v in symbol.node {
            case Struct_Decl:
            for m in v.members{
                if m.name == expr.member {
                    if nt, is := m.type.(NamedType); is {
                        type = checker_replace_named_type(t, nt)
                    }
                    else do type = m.type
                }
            }
        }
    }


    expr.type = type
    return type, scope
}


checker_get_type :: proc(t: ^SymbolTable, expr: ^Expr) -> (Type, ^SymbolTable) {
    if expr == nil do panic("Checker_get type expr is nil")
    switch &v in expr {
    case Expr_MemberAccess: return checker_memberaccess(t, &v);
    case Expr_Array:        panic("TODO")
    case Expr_Subscript:    return checker_subscript(t, &v);
    case Expr_Number:       return checker_get_number(t, &v)
    case Expr_String:       panic("TODO") // return checker_get_string(t, &v)
    case Expr_Identifier:   return checker_get_identifier_type(t, &v)
    case Expr_Binary:       return checker_get_binary_type(t, &v);
    case Expr_Call:         return checker_get_call_type(t, &v);
    case Expr_Unary:        return checker_get_unary(t, &v);
    }
    fmt.println(expr)
    panic("TODO")
}

check_type :: proc(a,b: Type) -> bool {
    if a == nil || b == nil do return false

    switch x in a {
    case StructType: return false
    case NamedType: return false
        
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

checker_variable_decl :: proc(t: ^SymbolTable, decl: ^Variable_Decl) -> Type {

    if decl.type != nil {
        type_symbol, f := symbol_table_lookup_type(t, decl.type)
        decl.type = checker_replace_named_type(t, decl.type)
        if !f do parser_panic(decl^, "Type not found when checking type")
    }
    if decl.initlizer != nil {
        it,_ := checker_get_type(t, decl.initlizer)

        it = checker_replace_named_type(t, it)

        expr_set_type(decl.initlizer, checker_replace_named_type(t, it))
        
        fmt.println("IT", it)
        if type, can := can_cast(decl.type, it); can {
            expr_set_type(decl.initlizer, type)
            decl.type = type
        }
        else if !check_type(decl.type, it) {
            parser_panic(decl^, fmt.tprintf("Variable declartion type missmatch %s != %s", type_to_string(decl.type), type_to_string(it)))
        }
        //panic("TODO")
    }
    return decl.type
}


check_block :: proc(package_: Package, func: Function_Decl, block: ^Block, t: ^SymbolTable) {
    for &items in block.items {
        switch &item in items {
        case Decl:
            switch &decl in item {
            case Variable_Decl:
                decl.type = checker_variable_decl(t, &decl)
                ok := symbol_table_set_type(t, decl.name, decl.type)
                fmt.println("=========CHECKED VARIABLE =========", decl.type)
                print_symbol_table(t^)
                fmt.println("===================================")
                if !ok do panic("PANIC, couldnt update type")

            case Function_Decl:
                panic("Function declartion not support in function")
                
            case Struct_Decl:
                panic("Struct declartion not support in function")
            case Package_Decl:
                panic("Package cant be in function")
            }
        case Stmt:
            switch &stmt in item {
                
            case Expr:
                ans,_ := checker_get_type(t, &stmt)
                // print_stmt(stmt);
            case Return_Stmt:
                type,_ := checker_get_type(t, stmt.value)
                stmt.type = type
            case If_Stmt:
                panic("TODO")

                // check_block(program, func, stmt.block, t);
                // if stmt.else_block != nil do check_block(program, func, stmt.else_block, t);

            case While_Stmt:
                panic("TODO")
                // checker_get_type(t, stmt.condition)
                // check_block(program, func, stmt.block, t);
                
            case Block:
                check_block(package_, func, &stmt, t)
            }
            
        }
    }
}

check :: proc(program: Program, t: ^SymbolTable) {
    for package_ in program.packages {
        package_t,found_package := symbol_table_lookup(t, package_.package_name)
        if !found_package do panic("PACKAGE NOT FOUND!??!?!")

        for &struc in package_.structs {
            for &member in struc.members {
                checker_variable_decl(t, member)
            }
        }

        for &func in package_.functions {
            if func.block == nil do continue

            // if func has no type we assign void to it (default)
            if func.type == nil do func.type = Basic(.VOID)

            func.type = checker_replace_named_type(t, func.type);

            func_t,found := symbol_table_lookup(package_t.scope, func.name)
            if !found do panic("FUNC NOT FOUND!??!?!")

            
            // go trough function block and check all types
            check_block(package_, func^, func.block, func_t.scope);
        }
    }
}

