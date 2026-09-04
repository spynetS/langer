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
    scope: ^SymbolTable
}


SymbolTable :: struct {
    symbols: map[string]Symbol,
    parent: ^SymbolTable,
    parent_symbol: Symbol
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

symbol_table_add_item :: proc(t: ^SymbolTable, key: string, value: Symbol) {
    if v, exists := t.symbols[key]; exists {
        parser_panic(value.node, fmt.tprintf("Redefinition"))
    }

    t.symbols[key] = value;
}

get_symbol_package :: proc(t: ^SymbolTable) -> string {
    if decl, is := t.parent_symbol.node.(Package_Decl); is {
        return decl.name
    }

    return get_symbol_package(t.parent)
}

create_symbol_table_func :: proc(t: ^SymbolTable, func: ^Function_Decl) -> ^SymbolTable {
    table := new(SymbolTable)
    table.parent = t

    decl := Decl(func^)
    symbol_table_add_item(t, func.name, new_symbol(&decl, func.type, .PUBLIC, table))
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
    symbol_table_add_item(t, struc.name, new_symbol(&decl, type, .PUBLIC, table))
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


create_symbol_table_program :: proc(symbol_table: ^SymbolTable, package_: Package) -> ^SymbolTable {

    package_t := new(SymbolTable)
    package_t.parent = symbol_table;
    pd := new(Decl)
    pd^ = Package_Decl{
        name = package_.package_name
    }

    package_t.parent_symbol = new_symbol(pd, nil, .PUBLIC, scope = package_t)
    symbol_table_add_item(symbol_table,
                          package_.package_name,
                          package_t.parent_symbol)

    // fmt.println("PACKGE DONE", package_.package_name)
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
        return symbol_table_lookup_path(t, v.path); 
        case StructType:
        return symbol_table_lookup_path(t, v.path);
        case Pointer: if v.to != nil do return symbol_table_lookup_type(t, v.to^)
        case Basic: return {}, true // the type exists but no symbol
        case Array: panic("TODO")
    }
    return {}, false
}


symbol_table_lookup_expr :: proc(t: ^SymbolTable, expr: ^Expr) -> (Symbol, bool) {
    if name, is := expr.(Expr_Identifier); is {
        // fmt.println("id searching for", name.value)
        return symbol_table_lookup_str(t, name.value)
    }

    if member, is := expr.(Expr_MemberAccess); is {
        // fmt.println("mem searching for", expr_to_string(member.obj^))
        if obj_t,found := symbol_table_lookup_expr(t, member.obj); found {
            return symbol_table_lookup(obj_t.scope, member.member)
        }
    }
    return {}, false
}

symbol_table_lookup_path :: proc(t: ^SymbolTable, path: [dynamic]string) -> (Symbol, bool) {
    if len(path) == 0 {
        return {}, false
    }

    // First name is resolved normally through lexical scopes.
    symbol, found := symbol_table_lookup_str(t, path[0])
    if !found {
        return {}, false
    }

    // Remaining names are resolved inside the previous symbol.
    for part in path[1:] {
        // Whatever mechanism you use to get the symbol table
        // belonging to the type/definition of `symbol`.
        scope := symbol.scope

        if scope == nil {
            return {}, false
        }

        symbol, found = symbol_table_lookup_str(scope, part)
        if !found {
            return {}, false
        }
    }

    return symbol, true
}

symbol_table_lookup_str :: proc(t: ^SymbolTable, name: string) -> (Symbol, bool) {
    current := t
    
    for current != nil {
        if symbol, found := current.symbols[name]; found {
            // fmt.println("FOUND",name)
            return symbol, true
        }
        // fmt.println("SEARCHING IN PARENT FOR",name)
        current = current.parent
//        print_symbol_table(current^)
    }

    // fmt.println("")

    return {}, false
}

print_symbol_table :: proc(t: SymbolTable, depth:int = 0) {

    for key, symbol in t.symbols {
        for i in 0..<depth do log(" ")
        logln(key, "->", decl_to_string(symbol.node))
        if symbol.scope != nil do print_symbol_table(symbol.scope^, depth+1)
    }
}
