package main;
import "core:strings"
import "core:fmt"

// compile .ll
// clang out.ll -o out

LLVM_Generator :: struct {
    strings: [dynamic]string
}

LLVM_Value :: struct {
    type: string,
    value: string
}


emit :: proc(b: ^strings.Builder, str:  ..string) {
    for s in str do strings.write_string(b, s)
}
emitln :: proc(b: ^strings.Builder, str:  ..string) {
    for s in str do strings.write_string(b, s)
    strings.write_string(b, "\n")
}

emit_string :: proc(g: ^LLVM_Generator, str: Expr_String) -> string {
    var := "@.str"
    length := len(str.value)
    size := "i8"
    str := fmt.tprintf("{} = private unnamed_addr constant [{} x {}] c%s\\00\"",var, length-1, size, str.value[:length-1])

    append(&g.strings, str)

    return var
}


get_tmp_var :: proc () -> string {
    return "%tmp"
}

get_expr_type :: proc(expr: Expr) -> Type {
    #partial switch v in expr {
    case Expr_Integer: return .INT
    case Expr_Identifier: return v.type
        case Expr_String:
        // TODO should be char
        to := new(Type)
        to^ = .INT
        return Pointer({to=to})
    case Expr_Call: return v.type
    }
    fmt.println(expr)
    panic("TODO")
}

get_llvm_type :: proc(type: Type) -> string {
    #partial switch v in type {
        case Basic:
        #partial switch v {
        case .INT:   return "i32"
        case .VOID:  return "void"
        case .FLOAT: return "float"
        case .STRING: return "ptr"
        }
        case Pointer: return "ptr"

    }
    fmt.println(type)
    return "<unknown type>"
}

get_op_cmd :: proc(kind: Token_Kind) -> string {
    #partial switch kind {
        case .PLUS: return "add"
        case .MINUS: return "sub"
    }
    panic("TODO")
}

get_expression :: proc(g: ^LLVM_Generator, expr_u: Expr, b: ^strings.Builder) -> LLVM_Value {
    bt := strings.builder_make()
    type := "nil"
    #partial switch expr in expr_u {
        case Expr_String:
        var := emit_string(g, expr)
        emit(&bt, var)
        type = "ptr"

        case Expr_Integer:
        emit(&bt, " ", expr.value)
        type = "i32"
        
        case Expr_Binary:
        var := get_tmp_var()
        emitln(b,
               var,
               " = ",
               get_op_cmd(expr.op),
               " ",
               get_llvm_type(get_expr_type(expr.left^)),
               get_expression(g, expr.left^, b).value,
               ", ",
               get_expression(g, expr.right^, b).value)
        emit(&bt, var)
        type = get_expression(g, expr.left^, b).type
        case Expr_Call:
        emit(&bt, "call ", get_llvm_type(expr.type), " (")

        for i in 0..<len(expr.args) {
            arg := expr.args[i]
            emit(&bt, get_llvm_type(get_expr_type(arg^)))
            if i < len(expr.args)-1 do emit(&bt, ", ")
        }

        emit(&bt, ")")
        emit(&bt, " @", expr.name, "(")
        for i in 0..<len(expr.args) {
            arg := expr.args[i]
            aexpr := get_expression(g, arg^, b)
            emit(&bt, aexpr.type," ", aexpr.value)
            if i < len(expr.args)-1 do emit(&bt, ", ")
                        

        }
        emit(&bt, ")")
        //, " (ptr,...) ", "@", expr.name, "(ptr, @.str)")
    }
    return LLVM_Value{
        type = type,
        value = strings.to_string(bt)
    }
}
gen_return :: proc(g: ^LLVM_Generator, stmt: Return_Stmt, b: ^strings.Builder) {
    expr := get_expression(g, stmt.value^, b)
    emitln(b, fmt.tprintf("ret {} {}", expr.type ,expr.value))
}

gen_block :: proc(g: ^LLVM_Generator, block: Block, b: ^strings.Builder) {
    for item in block.items {
        switch v in item {
        case Decl:
            panic("TODO")
        case Stmt:
            switch stmt in v {
            case Expr:
                emitln(b, get_expression(g, stmt, b).value)
            case Return_Stmt: gen_return(g, stmt, b)
            case If_Stmt: panic("TODO")
            case While_Stmt: panic("TODO")
            case Block: panic("TODO")
            }
        }
    }
}


gen_program :: proc (g: ^LLVM_Generator, p: Program) -> string {
    b := strings.builder_make()

    for func in p.functions {
        if func.extern {
            emit(&b, fmt.tprintf("declare %s @%s(", get_llvm_type(func.type), func.name))
            for i in 0..<len(func.args) {
                arg := func.args[i]
                emit(&b, get_llvm_type(arg.type))
                if i < len(func.args)-1 do emit(&b, ", ")
            }
            emitln(&b, ")")
            continue
        }


        emitln(&b, fmt.tprintf("define %s @%s()", get_llvm_type(func.type), func.name), "{")
        emitln(&b, "entry:")

        gen_block(g, func.block^, &b)

        emitln(&b, "}")
    }

    return strings.to_string(b)
}

start_gen :: proc(g: ^LLVM_Generator, p: Program) -> string {
    b:= strings.builder_make()
    for str in g.strings {
        emitln(&b, str)
    }
    return strings.to_string(b)
}
