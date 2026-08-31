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
    parent: ^SymbolTable
}

new_symbol :: proc(node: Decl, type: Type, visibilty: Visibilty, scope: ^SymbolTable) -> Symbol {
    s := Symbol({})
    s.node = node
    s.type = type
    s.visibilty = visibilty
    s.scope = scope
    return s
}

symbol_table_add_item :: proc(t: ^SymbolTable, key: string, value: Symbol) {
    if v, exists := t.symbols[key]; exists {
        parser_panic(value.node, fmt.tprintf("Redefinition"))
    }

    t.symbols[key] = value;
}

create_symbol_table_func :: proc(t: ^SymbolTable,func : Function_Decl) -> ^SymbolTable {
    table := new(SymbolTable)
    table.parent = t
    // FIXME dont hard code public
    symbol_table_add_item(t, func.name, new_symbol(func, func.type, .PUBLIC, table))
    for a in func.args {
        symbol_table_add_item(table, a.name, new_symbol(a, a.type, .PUBLIC, nil))
    }

    if func.block == nil do return table

    for item in func.block.items {
        if decl, is := item.(Decl); is {
            val := new_symbol(decl, decl_get_type(decl), .PUBLIC, nil);
            symbol_table_add_item(table, decl_get_name(decl), val)
        }
    }
    return table;
}

create_symbol_table_struc :: proc(t: ^SymbolTable, struc : Struct_Decl) -> ^SymbolTable {
    table := new(SymbolTable)
    table.parent = t
    type := NamedType({struc.name})
    // FIXME dont hard code public
    symbol_table_add_item(t, struc.name, new_symbol(struc, type, .PUBLIC, table))
    for a in struc.members {
        symbol_table_add_item(table, a.name, new_symbol(a, a.type, .PUBLIC, nil))
    }
    return table;
}


create_symbol_table_program :: proc(package_: Package) -> ^SymbolTable {
    table := new(SymbolTable)
    for struc in package_.structs {
        create_symbol_table_struc(table, struc)
    }
    for func in package_.functions {
        create_symbol_table_func(table, func)
    }
    return table
}

symbol_table_lookup :: proc {
    symbol_table_lookup_expr,
    symbol_table_lookup_str
}

symbol_table_lookup_expr :: proc(t: ^SymbolTable, expr: ^Expr) -> (Symbol, bool) {
    if name, is := expr.(Expr_Identifier); is {
        fmt.println("id searching for", name.value)
        return symbol_table_lookup_str(t, name.value)
    }

    if member, is := expr.(Expr_MemberAccess); is {
        fmt.println("mem searching for", expr_to_string(member.obj^))
        if obj_t,found := symbol_table_lookup_expr(t, member.obj); found {
            return symbol_table_lookup(obj_t.scope, member.member)
        }
    }
    return {}, false
}

symbol_table_lookup_path :: proc(t: ^SymbolTable, path: string) -> (Symbol, bool) {
    parts := strings.split(path, ".")

    if len(parts) == 0 {
        return {}, false
    }

    // First name is resolved normally through lexical scopes.
    symbol, found := symbol_table_lookup_str(t, parts[0])
    if !found {
        return {}, false
    }

    // Remaining names are resolved inside the previous symbol.
    for part in parts[1:] {
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
            fmt.println("FOUND",name)
            return symbol, true
        }
        fmt.println("SEARCHING IN PARENT FOR",name)
        current = current.parent
//        print_symbol_table(current^)
    }

    fmt.println("")

    return {}, false
}

print_symbol_table :: proc(t: SymbolTable, depth:int = 0) {
    
    for key, symbol in t.symbols {
        for i in 0..<depth do log(" ")
        logln(key, "->",decl_to_string(symbol.node))
        if symbol.scope != nil do print_symbol_table(symbol.scope^, depth+1)
    }
}
