package main;

import "core:strings"

emit :: proc(builder: ^strings.Builder, str: string, args: ..string) {
    strings.write_string(builder, str)
    for arg in args do strings.write_string(builder, arg)
    strings.write_string(builder, "\n")
}

gen_expression :: proc(expr: Expr) -> string {
    b: = strings.builder_make()
    
    #partial switch expr.kind {
        case .Binary:
        emit(&b, "mov eax, ", gen_expression(expr.left^))
        emit(&b, "mov eax, ", gen_expression(expr.right^))

        #partial switch expr.op {
            case .PLUS:  emit(&b, "add eax, ebx")
            case .MINUS:  emit(&b, "sub eax, ebx")
        }

    case .Integer:
        emit(&b, expr.value)
        case: panic("TODO expr")
    }
    return strings.to_string(b)
}
gen_stmt :: proc(stmt: Stmt) -> string {
    #partial switch v in stmt {
    case Expr:
        return gen_expression(v)
        case:
        panic("TODO stmt")

    }
    return ""
}

start_gen :: proc() -> string {
    return "global _start\nsection .text\n_start:\n"
}

end_gen :: proc() -> string {
    return "mov edi, eax\nmov eax, 60\nsyscall"
}

