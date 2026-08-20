package main;
import "core:fmt"
import "core:strings"
import "core:os"

main :: proc() {
    path := "./main.langer"
    bytes, error := os.read_entire_file_from_path(path, allocator=context.allocator)
    input := strings.clone_from_bytes(bytes)
    fmt.println(input)
    l := Lexer({input=input,lines=1})
    tokens := make([dynamic]Token)

    for l.cursor+1 < len(l.input)+1 {
        token := read_token(&l)
        token.file = path
        token.line = l.lines
        token.col = l.cursor/l.lines
        append(&tokens, token)
    }

    
    for token in tokens {
        fmt.print(token.kind)
        fmt.print(" ")
    }
    fmt.print("\n")
    for token in tokens {
        fmt.print(token.lexeme)
        fmt.print(" ")
    }
    append(&tokens, Token({kind=.EOF}))
    fmt.print("\n")
    parser := Parser({})
    parser.tokens = tokens

    program := parse_program(&parser)
    fmt.println("\n===Parsed program===")
    print_program(program)    

    // stmt := parse_stmt(&parser)
    // fmt.println("\n===Parsed statment===")
    // print_stmt(stmt)
    fmt.println("\n===generated asm===")
    init_generator()
    gen_asm := gen_program(program)

    fmt.println(start_gen())
    fmt.println(gen_asm)
    fmt.println(end_gen())

    file, ok := os.open("./main.asm", {os.File_Flag.Write, os.File_Flag.Create, os.File_Flag.Trunc})

    os.write_string(file, start_gen())
    os.write_string(file, gen_asm)
    os.write_string(file, end_gen())
    os.close(file)    
}
