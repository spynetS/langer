package main;

import "core:fmt"

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

create_symbol_table_program :: proc(package_: Package) -> ^SymbolTable {
    table := new(SymbolTable)
    for func in package_.functions {
        create_symbol_table_func(table, func)
    }
    return table
}

symbol_table_loopup :: proc {
    symbol_table_loopup_expr,
    symbol_table_loopup_str
}

symbol_table_loopup_expr :: proc(t: ^SymbolTable, expr: ^Expr) -> (Symbol, bool) {
    if name, is := expr.(Expr_Identifier); is {
        fmt.println("id searching for", name.value)
        return symbol_table_loopup_str(t, name.value)
    }

    if member, is := expr.(Expr_MemberAccess); is {
        fmt.println("mem searching for", expr_to_string(member.obj^))
        if obj_t,found := symbol_table_loopup_expr(t, member.obj); found {
            return symbol_table_loopup(obj_t.scope, member.member)
        }
    }
    return {}, false
}

symbol_table_loopup_str :: proc(t: ^SymbolTable, name: string) -> (Symbol, bool) {
    current := t

    for current != nil {
        if symbol, found := current.symbols[name]; found {
            fmt.println("FOUND",name)
            return symbol, true
        }
        fmt.println("SEARCHING IN PARENT FOR",name)
        current = current.parent
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
