package main;
import "core:path/filepath"
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
clang_stderr := false
execute_out := false
amnt_errors := 0

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
         if arg == "run" {
            execute_out = true
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
            clang_stdout = true
            clang_stderr = true
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

should_continue :: proc() {
    if amnt_errors > 0 do os.exit(1)
}

main :: proc() {


    parse_args();
    
    o_files := make([dynamic]string)
    defer delete(o_files)

    program := Program({})
    symbol_table := SymbolTable({})
    
    default_allocator := context.allocator
    

    for file in files {
        path := file

        bytes, error := os.read_entire_file_from_path(path, allocator=context.allocator)
        input := strings.clone_from_bytes(bytes)
        delete(bytes)
        logln(input)
        l := Lexer({input=input,lines=1, col=1, file=path})
        tokens := tokenize(&l)
        should_continue();
        
        print_tokens(tokens)

        parser := Parser({tokens=tokens})

        package_ := parse_package(&parser)
        package_.file = file
        print_package(package_)
        append(&program.packages, package_)
        should_continue();
        
        create_symbol_table_program(&symbol_table, package_, package_.package_name[:]);
        should_continue();
        
    }
    print_symbol_table(symbol_table);
    

    for package_ in program.packages {
        name := package_.package_name[len(package_.package_name)-1]
        package_t := symbol_table.symbols[name].scope
        symbol_table_import(package_t, package_)
    }
    
    //if true do panic("AFTER PARSING")
    check(program, &symbol_table)
    //if true do panic("AFTER PARSING")

    should_continue();
        
    for p in program.packages {
        print_package(p)
    }

    //if true do panic("asd")
    for package_ in program.packages {
        print_package(package_)

        llvm_path := strings.builder_make()
        strings.write_string(&llvm_path, "./")
        strings.write_string(&llvm_path, slashpath.name(package_.file))
        strings.write_string(&llvm_path, ".ll")

        g := LLVM_Generator({})
        gen_program(&g, package_, &symbol_table, package_.file, strings.to_string(llvm_path))
        should_continue();
        
        append(&o_files, strings.to_string(llvm_path))

    }
    logln("=========== symbol table ===========")
    print_symbol_table(symbol_table)
    exit_code := 0

    if len(o_files) > 0 {
        exit_code = compile_llvm(o_files)

        if clean_llvm {
            // cleanup
            for file in o_files {
                os.remove(file)
            }
        }
    }
    delete(files)

    if execute_out do run_exec()

    if exit_code != 0 do os.exit(exit_code)
}


compile_llvm :: proc (o_files: [dynamic]string) -> int {

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

    fmt.println(command)

    link_process,_ := os.process_start({
        working_dir="./",
        command=command,
        stdout= clang_stdout ? os.stdout : nil,
        stderr= clang_stderr ? os.stderr : nil
    })

    state,_ := os.process_wait(link_process)
    return state.exit_code
}

run_exec :: proc() -> int {
    command := make([]string,1)
    command[0],_ = filepath.abs(out_file)
    fmt.println(command)
    link_process,_ := os.process_start({
        working_dir="./",
        command=command,
        stdout= os.stdout,
        stderr= os.stderr
    })
    
    state,_ := os.process_wait(link_process)
    return state.exit_code
}
