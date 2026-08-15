package main;
import "core:fmt"
import "core:strings"
import "core:os"

main :: proc() {
    bytes,error := os.read_entire_file_from_path("./main.langer", allocator=context.allocator)
    input := strings.clone_from_bytes(bytes)
    fmt.println(input)
    l := Lexer({input=input})
    tokens := make([dynamic]Token)

    for l.cursor+1 < len(l.input)+1 {
        token := read_token(&l)
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

    stmt := parse_stmt(&parser)
    fmt.println("\n===Parsed statment===")
    print_stmt(stmt)
    fmt.println("\n===generated asm===")
    init_data()
    fmt.println(gen_stmt(stmt))

    gen_asm := gen_stmt(stmt)

    fmt.println(start_gen())
    fmt.println(gen_asm)
    fmt.println(end_gen())


    file, ok := os.open("./main.asm", {os.File_Flag.Write, os.File_Flag.Create, os.File_Flag.Trunc})

    os.write_string(file, start_gen())
    os.write_string(file, gen_asm)
    os.close(file)
    
//    os.write_string(file, end_gen())



}
