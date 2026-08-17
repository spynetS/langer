package main;

import "core:strings"
import "core:fmt"


Data :: struct {
    data : map[string]string,
    id : int
}

data_table: ^Data

init_data :: proc() {
    data_table = new(Data)
    data_table.data = make(map[string]string)
}

save_data :: proc (data: string) -> string {
    id := fmt.tprintf("data%d", data_table.id)
    data_table.id += 1
    data_table.data[id] = fmt.tprintf("%s db %s , 0", id, data)
    return id
}

emit :: proc(builder: ^strings.Builder, str: string, args: ..string) {
    strings.write_string(builder, str)
    for arg in args do strings.write_string(builder, arg)
    strings.write_string(builder, "\n")
}

gen_expression :: proc(expr_u: Expr, b:  ^strings.Builder) -> string {
    switch expr in expr_u {
        case Expr_Identifier:
        id := save_data(expr.value)
        emit(b, "lea rdi, [rel ", id, "]")
        case Expr_Call:
        for arg in expr.args {
            gen_expression(arg^, b)
        }
        emit(b, "xor eax, eax") // only for variadic calls (any amount of args)
        emit(b, "call ", expr.name)
        case Expr_Integer:
        emit(b, "mov rsi, ", expr.value)
        case Expr_Binary:
        gen_expression(expr.left^ ,b)
        gen_expression(expr.right^,b)

        emit(b, "pop rbx")
        emit(b, "pop rax")

        #partial switch expr.op {
            case .PLUS:
            emit(b, "add rax, rbx")
            emit(b, "push rax")

            case .MINUS:
            emit(b, "sub rax, rbx")
            emit(b, "push rax")

            case .GREATER:
            emit(b, "cmp rax, rbx")
            emit(b, "jle .L_end")
        }
        
        case: panic("TODO expr")
    }
    return strings.to_string(b^)
}


gen_block :: proc(block: Block, b: ^strings.Builder) {
    panic("TODO")
}
    
gen_if :: proc(stmt: If_Stmt, b: ^strings.Builder){
    gen_expression(stmt.condition^, b)
    gen_block(stmt.block^, b)
    gen_block(stmt.else_block^, b)
}

gen_stmt :: proc(stmt: Stmt) -> string {
    b: = strings.builder_make()
    #partial switch v in stmt {
    case Expr:
        gen_expression(v, &b)
        case If_Stmt:
        gen_if(v, &b)
        case:
        panic("TODO stmt")

    }
    return strings.to_string(b)
}

start_gen :: proc() -> string {
    b := strings.builder_make()
    strings.write_string(&b, "extern puts\nextern printf\nsection .data\n")
    for key, data in data_table.data {
        strings.write_string(&b, fmt.tprintf("%s\n", data))
    }
    strings.write_string(&b, "section .text\nglobal main\nmain:")
    return strings.to_string(b)
}

end_gen :: proc() -> string {
    return "\nxor eax, eax\nret"
}

