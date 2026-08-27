package main;
import "core:fmt"
import "core:strings"
import "core:os"
import "core:mem"
import "core:path/slashpath"


read_out_file : bool = false

verbose : int = 0
out_file := "a.out"
clean_llvm := true
files : [dynamic]string
clang_stdout := false

// TODO add forloop
// TODO seprate arrays and pointers
// TODO chars
// TODO 32 bit integers

logln :: proc (strs: ..any) {
    if verbose == 0 do return
    fmt.println(..strs)
}
log :: proc (strs: ..any) {
    if verbose == 0 do return
    fmt.print(..
strs)
}


parse_args :: proc () {
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
        if arg == "-S" {
            clean_llvm = false
            continue
        }
        if arg == "--clang-v" {
            clang_stdout = false
            continue
        }
        if arg == "-h" || arg == "--help" {
            fmt.println("Usage: langer [options]/file ")
            fmt.println("Options:")
            fmt.println("-o outfile")
            fmt.println("-S don't remove llvm .ll files")
            fmt.println("-v verbose (for debugging)")
            fmt.println("--clang-v verbose clang (for compiling llvm out)")
            continue
        }

        append(&files, arg)
    }
}


main :: proc() {


    parse_args();
    
    o_files := make([dynamic]string)
    defer delete(o_files)

    for file in files {
        path := file

        bytes, error := os.read_entire_file_from_path(path, allocator=context.allocator)
        input := strings.clone_from_bytes(bytes)
        delete(bytes)
        logln(input)
        l := Lexer({input=input,lines=1, col=1, file=path})
        
        tokens := make([dynamic]Token)
        defer {
            delete(tokens)
            // free lexer
            delete(l.input)
        }
        

        for l.cursor < len(l.input) {
            token := read_token(&l)
            append(&tokens, token)
        }
        append(&tokens, Token({kind=.EOF}))
        print_tokens(tokens)
   

        
        parser := Parser({tokens=tokens})
        arena: mem.Dynamic_Arena
        mem.dynamic_arena_init(&arena)
        defer mem.dynamic_arena_destroy(&arena);
        context.allocator = mem.dynamic_arena_allocator(&arena)

        program := parse_program(&parser)
        print_program(program)

        t := create_symbol_table(program);
        fmt.println("Ceated symbol")
//        print_symbol_table(t^) // FIXME segfault here

        check(program, t)
        print_program(program)


        llvm_path := strings.builder_make()
        strings.write_string(&llvm_path, "./")
        strings.write_string(&llvm_path, slashpath.name(file))
        strings.write_string(&llvm_path, ".ll")

        g := LLVM_Generator({})
        gen_program(&g,program, file, strings.to_string(llvm_path))
        append(&o_files, strings.to_string(llvm_path))

    }

    if len(o_files) > 0 {
        compile_llvm(o_files)

        if clean_llvm {
            // cleanup
            for file in o_files {
                os.remove(file)
            }
        }
    }
    
    delete(files)
}


compile_llvm :: proc (o_files: [dynamic]string) {

    // linker
    command := make([]string, len(o_files)+4)
    defer delete(command)

    command[0] =  "clang"
    index := 1
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
        stdout= clang_stdout ? os.stdout : nil,
        stderr= os.stderr
    })

    _,_ = os.process_wait(link_process)

}
