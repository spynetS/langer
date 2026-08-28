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
create_symbol_table_func :: proc(t: ^SymbolTable,func : Function_Decl) -> ^SymbolTable {
    table := new(SymbolTable)
    table.parent = t
    // FIXME dont hard code public
    t.symbols[func.name] = new_symbol(func, func.type, .PUBLIC, table);
    for a in func.args {
        table.symbols[a.name] = new_symbol(a, a.type, .PUBLIC, nil);
    }

    if func.block == nil do return table
    
    for item in func.block.items {
        if decl, is := item.(Decl); is {
            table.symbols[decl_get_name(decl)] = new_symbol(decl, decl_get_type(decl), .PUBLIC, nil);
        }
    }
    return table;
}

create_symbol_table :: proc(program: Program) -> ^SymbolTable {
    table := new(SymbolTable)
    for func in program.functions {
        create_symbol_table_func(table, func)
    }
    print_symbol_table(table^);
    return table
}

symbol_table_loopup :: proc(t: ^SymbolTable, name: string) -> (Symbol, bool) {
    current := t

    for current != nil {
        if symbol, found := current.symbols[name]; found {
            return symbol, true
        }

        current = current.parent
    }

    return {}, false
}

print_symbol_table :: proc(t: SymbolTable, depth:int = 0) {
    for key, symbol in t.symbols {
        for i in 0..<depth do fmt.print(" ")
        fmt.println(key, "->",decl_to_string(symbol.node))
        if symbol.scope != nil do print_symbol_table(symbol.scope^, depth+1)
    }
}
