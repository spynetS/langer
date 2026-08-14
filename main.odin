package main;
import "core:fmt"
import "core:strings"
import "core:os"

main :: proc() {
    input := "(1+1) + (1+1)"
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
    fmt.println("Parsed statment")
    print_stmt(stmt)
    fmt.println("")
    
    // file, ok := os.open("./main.asm", {os.File_Flag.Write, os.File_Flag.Create})
    // os.write_string(file, start_gen())

    // os.write_string(file, gen_stmt(stmt))
    
    // os.write_string(file, end_gen())
    // os.close(file)


}
