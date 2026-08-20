package main;

import "core:strings"
import "core:fmt"




Generator :: struct {
    data            : map[string]string,
    data_id         : int,
    scratch_name    : [8]string,
    scratch_inuse   : [8]bool,
    label_names     : [dynamic]string,
    label_bodies    : [dynamic]strings.Builder,
    arg_registers   : [8]string,
    variables       : map[string]string,
    stack           : [dynamic]map[string]string, // name to stack address
    current_stack   : int
}

generator: ^Generator
current_token: Token

label_create :: proc() -> int {
    index := len(generator.label_names)
    append(&generator.label_bodies, strings.builder_make())
    append(&generator.label_names, fmt.tprintf(".L%d", index+1))
    return index
}

label_name :: proc(index: int) -> string {
    return generator.label_names[index]
}
label_body :: proc(index: int) -> strings.Builder {
    return generator.label_bodies[index]
}

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
gen_stack_var :: proc(name, value: string) {
    assert(generator != nil)
    assert(len(generator.stack) > 0)
    // TODO check if its alreadt assign then crash
    generator.stack[get_stack_index()][name] = value
}

get_stack_index :: proc() -> int {
    return len(generator.stack)-1
}

get_var :: proc (name: string) -> string {
    if name in generator.stack[get_stack_index()] do return generator.stack[get_stack_index()][name]
    if name in generator.variables do return generator.variables[name]
    parser_panic(current_token,"Variable not declared")
    panic("")
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

enter_stack :: proc() {
    append(&generator.stack, make(map[string]string))
}
leave_stack :: proc() {
    pop(&generator.stack)
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
    strings.write_string(builder, str)
    fmt.print("EMIT:",str)
    for arg in args do fmt.printf("{}", arg)
    for arg in args do strings.write_string(builder, arg)
    strings.write_string(builder, "\n")
    fmt.print("\n")
}

gen_expression :: proc(expr_u: Expr, b:  ^strings.Builder) -> int {
    switch expr in expr_u {
    case Expr_String:
        //emit(b, "lea")
        return -1
    case Expr_Identifier:
        
        var := get_var(expr.value)
        index := scratch_alloc()
        emit(b, "mov ", scratch_name(index), ",", var)
        return index
    case Expr_Call:
        for i in 0..<len(expr.args) {
            index := len(expr.args)-1 - i
            arg := expr.args[index]
            #partial switch v in arg {
            case Expr_String:
                gen_expression(arg^, b)
                id := save_string(v.value)
                emit(b, "lea ", generator.arg_registers[index], ", [rel ",id, "]")
                case:
                register := gen_expression(v, b)
                emit(b, "mov ", generator.arg_registers[index], ", ", scratch_name(register))

            }
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

    if_block := label_create()
    bl := label_body(if_block)
    gen_block(stmt.block^, &bl)


    #partial switch con in stmt.condition {
        case Expr_Binary:
        l := gen_expression(con.left^, b)
        r := gen_expression(con.right^, b)
        emit(b, "cmp ",scratch_name(l),", ",scratch_name(r))
        if con.op == .EQ {
            emit(b, "je ", label_name(if_block))
        }
        else if con.op == .GEQ {
            emit(b, "jge ", label_name(if_block))
        }
        else if con.op == .LEQ {
            emit(b, "jle ", label_name(if_block))
        }

        
    }

    if stmt.else_block != nil do gen_block(stmt.else_block^, b);
    done := label_create()
    emit(b, "jmp ", label_name(done))
    emit(b, label_name(if_block), ":\n",strings.to_string(bl))
    emit(b, label_name(done), ":\n")
    

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

get_type_size :: proc (str: string) -> int {
    switch str {
    case "int": return 8
    case "float": return 32
    }
    return 0
}

gen_block :: proc(block: Block, b: ^strings.Builder, args: [dynamic]Variable_Decl = nil) -> string {

    enter_stack()

    size := 0
    if args != nil do for arg in args do size += get_type_size(arg.type)

    //emit(b, "push rbp\nmov rbp, rsp\nsub rsp, ", fmt.tprintf("%d",size), "\n" )

    i := 0
    size = 0
    if args != nil {
        for arg in args {
            fmt.println("gen arg", arg)
            size += get_type_size(arg.type)
            gen_stack_var(arg.name, fmt.tprintf("[rbp-{}]", size))
            emit(b, "mov ",get_var(arg.name),", ", generator.arg_registers[i])
            i+=1
        }
    }
    size = 0
    for item_u in block.items {
        switch item in item_u {
        case Decl:
            switch decl in item {
            case Function_Decl:
                panic("TODO")
            
            case Variable_Decl:
                size += get_type_size(decl.type)
                gen_stack_var(decl.name, fmt.tprintf("[rbp-{}]", size))
                index := gen_expression(decl.initlizer^, b)
                emit(b, "mov qword ",get_var(decl.name),", ", scratch_name(index))
            }
        case Stmt:
            strings.write_string(b, gen_stmt(item))
        }
    }
    leave_stack()
    return strings.to_string(b^)
}

gen_program :: proc(program: Program) -> string {
    b := strings.builder_make()
    for func in program.functions {
        emit(&b, func.name, ":\n")
        gen_block(func.block, &b, func.args)
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
    // for i in 0..<len(generator.label_names) {
    //     strings.write_string(&b, fmt.tprintf("%s:\n",label_name(i)))
    //     strings.write_string(&b, fmt.tprintf("%s\n",strings.to_string(label_body(i))))
    // }

    return strings.to_string(b)
}

end_gen :: proc() -> string {
    return "\nxor eax, eax\nret"
}


