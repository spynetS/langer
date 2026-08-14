package main;

import "core:strings"
import "core:fmt"

emit :: proc(builder: ^strings.Builder, str: string, args: ..string) {
    strings.write_string(builder, str)
    for arg in args do strings.write_string(builder, arg)
    strings.write_string(builder, "\n")
}

gen_expression :: proc(expr: Expr, b:  ^strings.Builder) -> string {
    fmt.println("generating for", expr.kind)
    #partial switch expr.kind {
        case .Integer:
        emit(b, "push ", expr.value)
        case .Binary:
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
    emit(b,"mov rax, 1")
    emit(b,"mov rdi, 1")
    emit(b,"mov rsi, msg")
    emit(b,"mov rdx, len")
    emit(b,"syscall")
}
    
gen_if :: proc(stmt: If_Stmt, b: ^strings.Builder){
    gen_expression(stmt.condition^, b)
    gen_block(stmt.block^, b)
    // else block fornow
    emit(b, ".L_end:")
    emit(b,"mov rax, 60")
    emit(b,"xor rdi, rdi")
    emit(b,"syscall")
    //gen_block(stmt.else_block^, b)
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
    return "section .data\nmsg db \"yes\", 10\nlen equ $ - msg\nglobal _start\nsection .text\n_start:\n"
}

end_gen :: proc() -> string {
    return "mov edi, eax\nmov eax, 60\nsyscall"
}

