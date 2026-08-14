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
            case .PLUS:  emit(b, "add rax, rbx")
            case .MINUS:  emit(b, "sub rax, rbx")
        }
        
        emit(b, "push rax")
        case: panic("TODO expr")
    }
    return strings.to_string(b^)
}
gen_stmt :: proc(stmt: Stmt) -> string {
    b: = strings.builder_make()
    #partial switch v in stmt {
    case Expr:
        return gen_expression(v, &b)
        case:
        panic("TODO stmt")

    }
    return strings.to_string(b)
}

start_gen :: proc() -> string {
    return "global _start\nsection .text\n_start:\n"
}

end_gen :: proc() -> string {
    return "mov edi, eax\nmov eax, 60\nsyscall"
}

