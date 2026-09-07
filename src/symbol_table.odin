package main;

import "core:fmt"
import "core:strings"

Visibilty :: enum {
    PRIVATE,
    PUBLIC
}

Symbol :: struct {
    node : Decl,
    visibilty: Visibilty,
    type: Type,
    scope: ^SymbolTable,
    // abit of a hack xd
    is_import: bool,
    import_name: []string
}


SymbolTable :: struct {
    symbols: map[string]Symbol,
    parent: ^SymbolTable,
    parent_symbol: Symbol,
    import_name: map[string]string 
}

// This is used to add package name infront of types that are defined inside the package
create_type :: proc(t: ^SymbolTable, type: ^Type) -> Type {

    logln("CREATING TYPE")
    switch &v in type {
    case StructType: panic("TODO")
    case Basic: return v
    case Pointer:
        if v.to != nil do v.to^ = create_type(t, v.to)
        return v
    case Array:
        if v.of != nil do return create_type(t, v.of)
    case NamedType:
        if t == nil do panic("NIL")
        // we we have package return it
        if len(v.path) > 1 do return v
        // we we don't we should add our
        package_name := get_symbol_package(t)

        for p in strings.split(package_name, ".") do inject_at(&v.path, 0 ,p)

        logln("path", v.path)

        return v
    }

    panic("TODO")
}

new_symbol :: proc(node: ^Decl, type: Type, visibilty: Visibilty, scope: ^SymbolTable) -> Symbol {
    // fmt.println("new symbol", node)
    // fmt.println("t", type)
    type := type // to make it adressable
    s := Symbol({})
    
    #partial switch v in node {
        case Variable_Decl, Function_Decl:
        if type == nil do break
        s.type = create_type(scope, &type)
        decl_set_type(node, s.type)
        
        case Struct_Decl:
        if type == nil do break
        s.type = create_type(scope, &type)

    }
    s.node = node^


    s.visibilty = visibilty
    s.scope = scope
    return s
}

symbol_table_set_type :: proc(t: ^SymbolTable, key: string, type: Type) -> bool {
    current : ^SymbolTable = t
    
    for current != nil {
        if symbol, found := current.symbols[key]; found {
            symbol.type = type
            decl_set_type(&symbol.node, type)
            current.symbols[key] = symbol
            return true
        }
        current = current.parent
    }
    return false
}

symbol_table_add_item :: proc(t: ^SymbolTable, key: string, value: Symbol, merge: bool = false) {

    if v, exists := t.symbols[key]; exists {
        parser_panic(value.node, fmt.tprintf("Redefinition of '{}'", key))
    }

    t.symbols[key] = value;
}
/* treverses the symboltable upwards until finding a package symbol */
get_symbol_package :: proc(t: ^SymbolTable) -> string {
    sb := strings.builder_make()
    if decl, is := t.parent_symbol.node.(Package_Decl); is {
        return decl.name
    }

    return get_symbol_package(t.parent)
}

get_full_symbol_package :: proc(t: ^SymbolTable) -> string {
    sb := strings.builder_make()
    if decl, is := t.parent_symbol.node.(Package_Decl); is {
        if t.parent.parent != nil {
            strings.write_string(&sb, get_full_symbol_package(t.parent))
            strings.write_string(&sb, "_")
        }

        strings.write_string(&sb, decl.name)

        return strings.to_string(sb)
    }
    return get_full_symbol_package(t.parent)
}


create_symbol_table_func :: proc(t: ^SymbolTable, func: ^Function_Decl) -> ^SymbolTable {
    table := new(SymbolTable)
    table.parent = t

    decl := Decl(func^)
    symbol_table_add_item(t,
                          func.name,
                          new_symbol(&decl, func.type, func.public ? .PUBLIC : .PRIVATE, table))
    func^ = decl.(Function_Decl)
    for &a in func.args {
        a_table := new(SymbolTable)
        a_table.parent = table
        a_decl := Decl(a^)
        symbol_table_add_item(table, a.name, new_symbol(&a_decl, a.type, .PUBLIC, a_table))
        a^ = a_decl.(Variable_Decl)
    }

    if func.block == nil do return table

    for &item in func.block.items {
        if decl, is := item.(Decl); is {
            a_table := new(SymbolTable)
            a_table.parent = table

            val := new_symbol(&decl, decl_get_type(decl), .PUBLIC, a_table);
            // we have to update the item body
            item^ = decl
            symbol_table_add_item(table, decl_get_name(decl), val)
        }
    }
    return table;
}

create_symbol_table_struc :: proc(t: ^SymbolTable, struc: ^Struct_Decl) -> ^SymbolTable {
    table := new(SymbolTable)
    table.parent = t

    type := new_named_type({struc.name})

    decl := Decl(struc^)
    symbol_table_add_item(t, struc.name, new_symbol(&decl, type, struc.public ? .PUBLIC : .PRIVATE , table))
    struc^ = decl.(Struct_Decl)

    
    for &a in struc.members {
        a_table := new(SymbolTable)
        a_table.parent = table
        a_decl := Decl(a^)
        sym := new_symbol(&a_decl, a.type, .PUBLIC, a_table)
        a^ = a_decl.(Variable_Decl)
        symbol_table_add_item(table, a.name, sym)
    }
    return table;
}


create_symbol_table_program :: proc(symbol_table: ^SymbolTable, package_: Package, path: []string) -> ^SymbolTable {
    for i in 0..<len(path)-1 {
        name := path[i]
        found := false
        // check if name exists as package
        for key, sym in symbol_table.symbols {
            _, is := sym.node.(Package_Decl);
            if key == name && is {
                return create_symbol_table_program(sym.scope, package_, path[1:])
            }
        }
        if !found {
            parent := create_symbol_table_program(symbol_table,
                                                  Package{
                                                      package_name = path[:1]
                                                  },
                                                  path[:1])
            return create_symbol_table_program(parent, package_, path[1:])
            
        }
    }
    return create_symbol_table_package(symbol_table, package_)
}

symbol_table_import :: proc(package_t: ^SymbolTable, package_: Package) {
    for &imp in package_.imports {
        path := imp.path[len(imp.path)-1]
        symb, found := symbol_table_lookup_path(package_t, imp.path[:])
        // TODO use imp instead of span so we can see the code in the error
        if !found do parser_panic(imp.span, "Did not found import, did you include the package in compilatio?")
        symb.is_import = true
        symb.import_name = imp.path[:]
        symbol_table_add_item(package_t, path, symb)
    }
}
create_symbol_table_package :: proc(symbol_table: ^SymbolTable, package_: Package) -> ^SymbolTable {
    name := package_.package_name[len(package_.package_name)-1]
    package_t : ^SymbolTable
    
    if pt, exists := symbol_table.symbols[name]; exists {
        package_t = pt.scope
    } else {
        
        package_t = new(SymbolTable)
        package_t.parent = symbol_table;
        pd := new(Decl)
        pd^ = Package_Decl{
            name = name
        }

        package_t.parent_symbol = new_symbol(pd, nil, .PUBLIC, scope = package_t)
        symbol_table_add_item(symbol_table,
                              name,
                              package_t.parent_symbol)
    }

    for &struc in package_.structs {
        create_symbol_table_struc(package_t, struc)
    }
    for &func in package_.functions {
        create_symbol_table_func(package_t, func)
    }
    // fmt.println("DONEN")
    return package_t;
}

symbol_table_lookup :: proc {
    symbol_table_lookup_expr,
    symbol_table_lookup_str
}

symbol_table_lookup_type :: proc(t: ^SymbolTable, type: Type) -> (Symbol, bool) {

    #partial switch v in type {
        case NamedType:
        return symbol_table_lookup_path(t, v.path[:]); 
        case StructType:
        return symbol_table_lookup_path(t, v.path[:]);
        case Pointer: if v.to != nil do return symbol_table_lookup_type(t, v.to^)
        case Basic: return {}, true // the type exists but no symbol
        case Array: panic("TODO")
    }
    return {}, false
}


symbol_table_lookup_expr :: proc(t: ^SymbolTable, expr: ^Expr) -> (Symbol, bool) {

    if name, is := expr.(Expr_Identifier); is {
        return symbol_table_lookup_str(t, name.value)
    }

    if member, is := expr.(Expr_MemberAccess); is {
        if obj_t,found := symbol_table_lookup_expr(t, member.obj); found {
            return symbol_table_lookup_str(obj_t.scope, member.member)
        }
    }
    return {}, false
}

symbol_table_lookup_str :: proc(t: ^SymbolTable, name: string) -> (Symbol, bool) {
    current := t
    for current != nil {
        if symbol, found := current.symbols[name]; found {
            return symbol, true
        }
        current = current.parent
    }
    return {}, false
}


symbol_table_lookup_path :: proc(t: ^SymbolTable, path: []string) -> (Symbol, bool) {
    if len(path) == 0 {
        return {}, false
    }
    in_different_package := false
    // First name is resolved normally through lexical scopes.
    symbol, found := symbol_table_lookup_str(t, path[0])
    if !found {
        return {}, false
    }

    // Remaining names are resolved inside the previous symbol.
    for part in path[1:] {
        // Whatever mechanism you use to get the symbol table
        // belonging to the type/definition of `symbol`.
        if _, is_package := symbol.node.(Package_Decl); is_package {
            in_different_package = true
        }
        scope := symbol.scope

        if scope == nil {
            return {}, false
        }

        symbol, found = symbol_table_lookup_str(scope, part)
        if !found {
            return {}, false
        }
    }

    if in_different_package && symbol.visibilty == .PRIVATE {
        // FIXME should be panic here?
        parser_panic(decl_get_span(symbol.node), "Can't access this delceration because its private")
        return {}, false
    }
    else do return symbol, true
    
}


print_symbol_table :: proc(t: SymbolTable, depth:int = 0) {

    for key, symbol in t.symbols {
        for i in 0..<depth do log(" ")
        logln(key, "->", decl_to_string(symbol.node))
        if symbol.scope != nil do print_symbol_table(symbol.scope^, depth+1)
    }
}
