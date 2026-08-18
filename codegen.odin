package main;

import "core:strings"
import "core:fmt"




Generator :: struct {
    data : map[string]string,
    data_id : int,
    scratch_name:   [8]string,
    scratch_inuse:  [8]bool,
    arg_registers:  [8]string,
    variables    :  map[string]string,
}

generator: ^Generator

save_string :: proc (str: string) -> string {
    assert(generator != nil)

    id := fmt.tprintf("string{}", generator.data_id)
    generator.data_id += 1
    generator.data[id] = str
    return id
}

gen_var :: proc(name, value: string) {
    assert(generator != nil)
    // TODO check if its alreadt assign then crash
    generator.variables[name] = value
}

get_var :: proc (name: string) -> string {
    if name in generator.variables do return generator.variables[name]
    panic("Variable not declared")
}

scratch_alloc :: proc () -> int {
    assert(generator != nil)

    for i in 0..<len(generator.scratch_inuse) {
        if generator.scratch_inuse[i] == false {
            generator.scratch_inuse[i] = true
            return i
        }
    }
    panic("no scrateches aviable")
}

scratch_free :: proc (index: int) {
    generator.scratch_inuse[index] = false
}
scratch_name :: proc (index: int) -> string {
    return generator.scratch_name[index]
}

init_generator :: proc() {

    generator = new(Generator)
    generator.data = make(map[string]string)
    generator.scratch_name[0] = "rbx"
    generator.scratch_name[1] = "r10"
    generator.scratch_name[2] = "r11"
    generator.scratch_name[3] = "r12"
    generator.scratch_name[4] = "r13"
    generator.scratch_name[5] = "r14"
    generator.scratch_name[6] = "r15"
    generator.scratch_name[7] = "rax"

    generator.arg_registers[0] = "rdi"
    generator.arg_registers[1] = "rsi"
    generator.arg_registers[2] = "rdx"
    generator.arg_registers[3] = "rsx"
    generator.arg_registers[4] = "r8"
    generator.arg_registers[5] = "r9"

    for i in 0..<7 do generator.scratch_inuse[i] = false
}


emit :: proc(builder: ^strings.Builder, str: string, args: ..string) {
    fmt.println("EMIT:",str)
    strings.write_string(builder, str)
    for arg in args do strings.write_string(builder, arg)
    strings.write_string(builder, "\n")
}

gen_expression :: proc(expr_u: Expr, b:  ^strings.Builder) -> int {
    switch expr in expr_u {
    case Expr_String:
        //emit(b, "lea")
        return -1
    case Expr_Identifier:
        if expr.value in generator.variables {
            index := scratch_alloc()
            emit(b, "mov ", scratch_name(index), ", [rel ", expr.value, "]")
            return index
        }
        return -1
    case Expr_Call:
        i := 0
        for arg in expr.args {
            #partial switch v in arg {
            case Expr_String:
                gen_expression(arg^, b)
                id := save_string(v.value)
                emit(b, "lea ", generator.arg_registers[i], ", [rel ",id, "]")
                case:
                index := gen_expression(v, b)
                emit(b, "mov ", generator.arg_registers[i], ", ", scratch_name(index))

            }

            i += 1
        }
        pops := make([dynamic]string)
        for i in 0..<len(generator.scratch_inuse) {
            if generator.scratch_inuse[i] {
                emit(b, "push ", generator.scratch_name[i])
                append(&pops, generator.scratch_name[i])
            }
        }
        emit(b, "xor eax, eax") // only for variadic calls (any amount of args)
        emit(b, "call ", expr.name, "\n")
        // pop backwards
        for i in 0..<len(pops) {
            if generator.scratch_inuse[i] {
                emit(b, "pop ", pops[(len(pops)-1)-i])
            }
        }
        emit(b, "\n")

        return 7 // return address
    case Expr_Integer:
        index := scratch_alloc();
        emit(b, "mov ", scratch_name(index), ", ", expr.value)
        return index
    case Expr_Binary:
        ar := gen_expression(expr.left^ ,b)
        br := gen_expression(expr.right^,b)

        #partial switch expr.op {
        case .PLUS:
            emit(b, "add ", scratch_name(ar), ", ", scratch_name(br ))
            scratch_free(br)
            return ar
        case .MINUS:
            emit(b, "sub ", scratch_name(ar), ", ", scratch_name(br ))
            scratch_free(br)
            return ar
        case .MULT:
            emit(b, "imul ", scratch_name(ar), ", ", scratch_name(br ))
            scratch_free(br)
            return ar
            case .GREATER:
            panic("TODO")
            case .LESS:
            panic("TODO")
            case .EQUAL:
            var := get_var(expr.left.(Expr_Identifier).value)
            index := gen_expression(expr.right^, b)
            emit(b, "mov qword [rel ", var, "], ", scratch_name(index))
            scratch_free(index)
            return -1
        }
        
        case: panic("TODO expr")
    }
    fmt.println(expr_u)
    panic("TODO")
}

    
gen_if :: proc(stmt: If_Stmt, b: ^strings.Builder){
    //panic("TODO")
}

gen_stmt :: proc(stmt: Stmt) -> string {
    b: = strings.builder_make()
    #partial switch v in stmt {
    case Expr:
        gen_expression(v, &b)
        case If_Stmt:
        gen_if(v, &b)
        case Return_Stmt:
        index := gen_expression(v.value^, &b)
        emit(&b, "mov rax,", scratch_name(index))
        case:
        fmt.println(stmt)
        panic("TODO stmt")

    }
    return strings.to_string(b)
}


gen_block :: proc(block: Block, b: ^strings.Builder) -> string {
    for item_u in block.items {
        switch item in item_u {
        case Decl:
            switch decl in item {
            case Function_Decl:
                panic("TODO")
            
            case Variable_Decl:
                gen_var(decl.name, "dq 0")
                index := gen_expression(decl.initlizer^, b)
                emit(b, "mov qword [rel ",decl.name,"], ", scratch_name(index))
            }
        case Stmt:
            strings.write_string(b, gen_stmt(item))
        }
    }
    return strings.to_string(b^)
}

gen_program :: proc(program: Program) -> string {
    b := strings.builder_make()
    for func in program.functions {
        emit(&b, func.name, ":\n")
        gen_block(func.block, &b)
        emit(&b, "ret")
    }
    return strings.to_string(b)
}

start_gen :: proc() -> string {
    b := strings.builder_make()
    strings.write_string(&b, "extern puts\nextern printf\nsection .data\n")
    for key, data in generator.data {
        strings.write_string(&b, fmt.tprintf("%s db %s, 0\n",key, data))
    }
    for key, data in generator.variables {
        strings.write_string(&b, fmt.tprintf("%s: %s\n",key, data))
    }
    strings.write_string(&b, "section .text\nglobal main\n")
    return strings.to_string(b)
}

end_gen :: proc() -> string {
    return "\nxor eax, eax\nret"
}

