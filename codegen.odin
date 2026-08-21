package main;

import "core:strings"
import "core:fmt"
import "core:strconv"

import "base:runtime"



Generator :: struct {
    data            : map[string]string,
    data_id         : int,
    scratch_name    : [8]string,
    scratch_inuse   : [8]bool,
    label_names     : [dynamic]string,
    label_bodies    : [dynamic]strings.Builder,
    arg_registers   : [8]string,
    variables       : map[string]string,
    stack           : [dynamic]map[string]int, // name to stack address
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

get_var_name :: proc(offset:int) -> string {
    return fmt.tprintf("[rbp-{}]", offset)
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
gen_stack_var :: proc(name: string, offset: int) {
    assert(generator != nil)
    assert(len(generator.stack) > 0)
    // TODO check if its alreadt assign then crash
    generator.stack[get_stack_index()][name] = offset
}

get_stack_index :: proc() -> int {
    return len(generator.stack)-1
}

get_var :: proc (name: string) -> int {
    if name in generator.stack[get_stack_index()] do return generator.stack[get_stack_index()][name]
    else if name in generator.stack[get_stack_index()] do return generator.stack[get_stack_index()][name]
    //if name in generator.variables do return generator.variables[name]
    parser_panic(current_token,fmt.tprintf("Variable {} not declared", name))
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
    append(&generator.stack, make(map[string]int))
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
  //  log("EMIT:",str)
//    for arg in args do logln(arg)
    for arg in args do strings.write_string(builder, arg)
    strings.write_string(builder, "\n")
    //log("\n")
}

gen_expression :: proc(expr_u: Expr, b:  ^strings.Builder) -> int {
    switch expr in expr_u {
    case Expr_Subscript:
        reg := scratch_alloc()
        var := get_var(expr.left.value)

        // load the base value (pointer OR array-slot-address, per the pointer/array split)
        emit(b, "mov ", scratch_name(reg), ", ", get_var_name(var))

        idx_reg := gen_expression(expr.index^, b)   // works for Expr_Integer,
        // Expr_Identifier, Expr_BinaryOp, calls, etc.

        // reg = reg + idx_reg*8   (x86 lets you fold *8 into addressing direcntly)
        emit(b, "mov ", scratch_name(reg), ", [", scratch_name(reg), "+", scratch_name(idx_reg), "*8]")

        scratch_free(idx_reg)
        return reg
    case Expr_Array:
        return -1//register
    case Expr_String:
        sid := save_string(expr.value)
        index := scratch_alloc()
        emit(b, "lea ", scratch_name(index), ", [rel ", sid ,"]")
        return index
    case Expr_Identifier:
        var := get_var(expr.value)
        index := scratch_alloc()
        emit(b, "mov ", scratch_name(index), ",", get_var_name(var))
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
                scratch_free(register)
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

        #partial switch expr.op {
            case .PLUS:
            ar := gen_expression(expr.left^ ,b)
            br := gen_expression(expr.right^,b)
            emit(b, "add ", scratch_name(ar), ", ", scratch_name(br ))
            scratch_free(br)
            return ar
            case .MINUS:
            ar := gen_expression(expr.left^ ,b)
            br := gen_expression(expr.right^,b)
            emit(b, "sub ", scratch_name(ar), ", ", scratch_name(br ))
            scratch_free(br)
            return ar
            case .STAR:
            ar := gen_expression(expr.left^ ,b)
            br := gen_expression(expr.right^,b)
            emit(b, "imul ", scratch_name(ar), ", ", scratch_name(br ))
            scratch_free(br)
            return ar
            case .GREATER:
            panic("TODO")
            case .LESS:
            panic("TODO")
            case .EQUAL:
            index := gen_expression(expr.right^, b)
            #partial switch left in expr.left {
                case Expr_Identifier:
                var := get_var(left.value)
                emit(b, "mov qword ", get_var_name(var), ", ", scratch_name(index))
                
                case Expr_Subscript:
                var := get_var(left.left.value)
                // idx_offset := 0
                // #partial switch expr in left.index {
                //     case Expr_Integer:
                //     value,ok := strconv.parse_int(expr.value)
                //     if !ok do panic("Integers only in subsc")
                //     idx_offset = 8 * value
                //     case:
                //     panic("Integers only in subsc")
                // }
                ptr_reg := scratch_alloc()
                // load the pointer's value off the stack
                emit(b, "mov ", scratch_name(ptr_reg), ", ", get_var_name(var))
                idx_reg := gen_expression(left.index^, b)   // works for Expr_Integer,
                // store THROUGH it, at the given byte offset
                //emit(b, "mov qword [", scratch_name(ptr_reg), "+", fmt.tprintf("{}",idx_offset), "], ", scratch_name(index))
                emit(b, "mov qword ", "[", scratch_name(ptr_reg), "+", scratch_name(idx_reg), "*8], ", scratch_name(index))

                scratch_free(ptr_reg)
            }
            scratch_free(index)

            return -1
        }
        
        case: panic("TODO expr")
    }
    logln(expr_u)
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
        if      con.op == .EQ      do emit(b, "je ",  label_name(if_block))
        else if con.op == .GEQ     do emit(b, "jge ", label_name(if_block))
        else if con.op == .LEQ     do emit(b, "jle ", label_name(if_block))
        else if con.op == .LESS    do emit(b, "jl ",  label_name(if_block))
        else if con.op == .GREATER do emit(b, "jg ",  label_name(if_block))
    }

    if stmt.else_block != nil do gen_block(stmt.else_block^, b);
    // this is so we skip the if block if we should run it
    done := label_create()
    emit(b, "jmp ", label_name(done))
    emit(b, label_name(if_block), ":\n",strings.to_string(bl))
    emit(b, label_name(done), ":\n")
    

}

gen_while :: proc(stmt: While_Stmt, b: ^strings.Builder) {
    while_block := label_create()
    //bl := label_body(while_block)
    emit(b, label_name(while_block), ":\n")
    gen_block(stmt.block^, b)

    #partial switch con in stmt.condition {
        case Expr_Binary:
        l := gen_expression(con.left^, b)
        r := gen_expression(con.right^, b)
        emit(b, "cmp ",scratch_name(l),", ",scratch_name(r))
        if      con.op == .EQ      do emit(b, "je ",  label_name(while_block))
        else if con.op == .GEQ     do emit(b, "jge ", label_name(while_block))
        else if con.op == .LEQ     do emit(b, "jle ", label_name(while_block))
        else if con.op == .LESS    do emit(b, "jl ",  label_name(while_block))
        else if con.op == .GREATER do emit(b, "jg ",  label_name(while_block))
    }

    

}

gen_stmt :: proc(stmt: Stmt) -> string {
    b: = strings.builder_make()
    #partial switch v in stmt {
    case Expr:
        gen_expression(v, &b)
        case While_Stmt:
        gen_while(v, &b)
        case If_Stmt:
        gen_if(v, &b)
        case Return_Stmt:
        index := gen_expression(v.value^, &b)
        emit(&b, "mov rax,", scratch_name(index))
        emit(&b, "leave\n")
        emit(&b, "ret\n")
        case:
        logln(stmt)
        panic("TODO stmt")

    }
    return strings.to_string(b)
}

get_type_size :: proc (type: string) -> int {
    str := strings.to_lower(type)
    switch str {
    case "string": return 8
    case "int": return 8
    case "int_arr": return 8
    case "float": return 32
    }
    return 0
}

gen_block :: proc(block: Block, b: ^strings.Builder, args: [dynamic]Variable_Decl = nil, new_stack: bool = false) -> string {
    if new_stack {
        enter_stack()
        emit(b, "push rbp\nmov rbp, rsp")
    }
    // CALCULATING STACK SPACE NEEDED
    size := 0
    if args != nil do for arg in args do size += get_type_size(arg.type)
        for item_u in block.items {
        #partial switch item in item_u {
            case Decl:
            #partial switch decl in item {
                case Variable_Decl: 
                type_size := get_type_size(decl.type)

                #partial switch expr in decl.initlizer {
                    case Expr_Array:
                    size += type_size * (len(expr.values)-1)
                }
                size += type_size

            }
        }
    }
    emit(b, "sub rsp, ", fmt.tprintf("%d", size))

    i := 0
    size = 0
    if args != nil {
        for arg in args {
            logln("gen arg", arg)
            size += get_type_size(arg.type)
            gen_stack_var(arg.name, size)
            emit(b, "mov ",get_var_name(get_var(arg.name)),", ", generator.arg_registers[i])
            i+=1
        }
    }

    had_return := false
    for item_u in block.items {
        switch item in item_u {
        case Decl:
            switch decl in item {
            case Function_Decl:
                panic("TODO")
            
            case Variable_Decl:
                size += get_type_size(decl.type)
                gen_stack_var(decl.name, size)
                #partial switch expr in decl.initlizer {
                    case Expr_Array:
                    for i in 0..<len(expr.values) {
                        val := expr.values[i]
                        index := gen_expression(val^, b)
                        emit(b, "mov qword [rbp-", fmt.tprintf("%d", (i+1)*get_type_size(decl.type)), "], ", scratch_name(index))
                        scratch_free(index)
                    }
                    case:
                    index := gen_expression(decl.initlizer^, b)
                    emit(b, "mov qword ", get_var_name(get_var(decl.name)), ", ", scratch_name(index))
                    scratch_free(index)
                }

            }
        case Stmt:
            strings.write_string(b, gen_stmt(item))
            #partial switch stmt in item {
                case Return_Stmt:
                logln("RETURN SO WE SHOULD POP")
                had_return = true
            }

        }
    }
    if new_stack {
        if !had_return do emit(b, "leave\n")
        leave_stack()
    }
    return strings.to_string(b^)
}

gen_start :: proc (b: ^strings.Builder) {
    emit(b,"global _start\n")
    emit(b,"_start:\n")
    emit(b,"call main\n")
    emit(b,"mov edi, eax\nmov eax, 60\nsyscall\n")
}

gen_program :: proc(program: Program) -> string {
    b := strings.builder_make()
    for func in program.functions {
        if func.extern do continue
        //if func.name == "main" do gen_start(&b)
        emit(&b,"global ", func.name, "\n")
        emit(&b, func.name, ":\n")
        gen_block(func.block^, &b, func.args, true)

        emit(&b, "ret\n")
    }
    return strings.to_string(b)
}

start_gen :: proc(program: Program) -> string {
    b := strings.builder_make()
    for func in program.functions {
        if !func.extern do continue
        strings.write_string(&b, fmt.tprintf("extern %s\n", func.name))
    }
    strings.write_string(&b, "\nsection .data\n")
    for key, data in generator.data {
        strings.write_string(&b, fmt.tprintf("%s db %s, 0\n",key, data))
    }
    for key, data in generator.variables {
        strings.write_string(&b, fmt.tprintf("%s: %s\n",key, data))
    }
    strings.write_string(&b, "section .text\n")
    // for i in 0..<len(generator.label_names) {
    //     strings.write_string(&b, fmt.tprintf("%s:\n",label_name(i)))
    //     strings.write_string(&b, fmt.tprintf("%s\n",strings.to_string(label_body(i))))
    // }

    return strings.to_string(b)
}

end_gen :: proc() -> string {
    return "\nxor eax, eax\nret"
}


