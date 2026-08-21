package main;
import "core:fmt"
import "core:strings"
import "core:os"
import "core:path/slashpath"


read_out_file : bool = false

verbose : int = 0
out_file := "a.out"

// TODO add forloop
// TODO seprate arrays and pointers
// TODO chars
// TODO 32 bit integers
// TODO floats

logln :: proc (strs: ..any) {
    if verbose == 0 do return
    fmt.println(..strs)
}
log :: proc (strs: ..any) {
    if verbose == 0 do return
    fmt.print(..
strs)
}


main :: proc() {

    files := make([dynamic]string)

    for arg, i in os.args {
        if i == 0 do continue
        if read_out_file {
            out_file = arg
            read_out_file = false
            continue
        }
        if arg == "-o" {
            read_out_file = true
            continue
        }
        if arg == "-v" {
            verbose = 1
            continue
        }
        append(&files, arg)
    }

    o_files := make([dynamic]string)

    for file in files {
        path := file

        bytes, error := os.read_entire_file_from_path(path, allocator=context.allocator)
        input := strings.clone_from_bytes(bytes)
        logln(input)
        l := Lexer({input=input,lines=1, col=1, file=path})
        tokens := make([dynamic]Token)

        for l.cursor < len(l.input) {
            token := read_token(&l)
            append(&tokens, token)
        }

        for token in tokens {
            log(token.kind)
            log(" ")
        }
        log("\n")
        for token in tokens {
            log(token.lexeme)
            log(" ")
        }

        append(&tokens, Token({kind=.EOF}))

        parser := Parser({}) 
        parser.tokens = tokens

        program := parse_program(&parser)
        logln("\n===Parsed program===")
        print_program(program)
        check(program)

        // stmt := parse_stmt(&parser)
        // logln("\n===Parsed statment===")
        // print_stmt(stmt)
        logln("\n===generated asm===")
        init_generator()
        gen_asm := gen_program(program)

        logln(start_gen(program))
        logln(gen_asm)
        logln(end_gen())

        asm_path := strings.builder_make()
        strings.write_string(&asm_path, "./")
        strings.write_string(&asm_path, slashpath.name(file))
        strings.write_string(&asm_path, ".asm")



        file, ok := os.open(strings.to_string(asm_path), {os.File_Flag.Write, os.File_Flag.Create, os.File_Flag.Trunc})
        logln(strings.to_string(asm_path))

        os.write_string(file, start_gen(program))
        os.write_string(file, gen_asm)
        os.write_string(file, end_gen())
        os.close(file)

        // compile o object
        
        out_path := strings.builder_make()
        strings.write_string(&out_path, "./")
        strings.write_string(&out_path, slashpath.name(strings.to_string(asm_path)))
        strings.write_string(&out_path, ".o")
        
        nsm_process,_ := os.process_start({
            working_dir="./",
            command={"nasm", "-f", "elf64", strings.to_string(asm_path), "-o", strings.to_string(out_path)},
            stdout= os.stdout,
            stderr= os.stderr,            
        })

        _,_ = os.process_wait(nsm_process)

        append(&o_files, strings.to_string(out_path))
    }

    // linker
    command := make([]string, len(o_files)+4)
    defer delete(command)

    command[0] =  "gcc"
    command[1] = "-no-pie"
    index := 2
    for file in o_files {
        command[index] = file
        index+=1
    }
    command[index] = "-o"
    index+=1
    command[index] = out_file

    link_process,_ := os.process_start({
        working_dir="./",
        command=command,
        stdout= os.stdout,
        stderr= os.stderr
    })

    _,_ = os.process_wait(link_process)

    // cleanup
    for file in o_files {
        os.remove(file)
    }
    
}
