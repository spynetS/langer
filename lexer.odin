package main;
import "core:fmt"
import "core:strings"

/*
| Token type                   | Examples                                                              |
| ---------------------------- | --------------------------------------------------------------------- |
| **Keywords**                 | `if`, `while`, `return`, `class`, `int`                               |
| **Identifiers**              | `x`, `myVariable`, `calculateTotal`                                   |
| **Literals**                 | `42`, `3.14`, `"hello"`, `'a'`, `true`                                |
| **Operators**                | `+`, `-`, `*`, `/`, `==`, `&&`, `=`                                   |
| **Punctuation / delimiters** | `(`, `)`, `{`, `}`, `[`, `]`, `,`, `;`                                |
| **Comments**                 | `// comment`, `/* comment */` — often discarded                       |
| **Whitespace**               | spaces, tabs, newlines — usually discarded, but sometimes significant |
| **Special tokens**           | EOF, errors, sometimes indentation/newline tokens                     |


identifier = [a-zA-Z_][a-zA-Z0-9_]*
integer    = [0-9]+
float      = [0-9]+\.[0-9]+
whitespace = [ \t\n\r]+
*/
MAX_DEPTH :: 10

Lexer :: struct {
    input: string,
    cursor: int,
    lines: int
}


Token_Kind :: enum {
    INVALID,
    EXTERN,
    NUMBER,
    EQUAL,
    COLON,
    SEMICOLON,
    IDENTIFER,
    STRING,
    STRING_TYPE,
    LET,
    VOID,
    INT,
    FLOAT,
    DOUBLE,
    FUNC,
    START,
    END,
    LPAR,
    RPAR,
    PLUS,
    MINUS,
    MULT,
    DIVIDE,
    PUNCT,
    COMMA,
    IF,
    ELSE,
    WHILE,
    LESS,
    GREATER,
    EQ,
    LEQ,
    GEQ,
    RETURN,
    EOF,
    LB,
    RB

}

Token :: struct {
    kind : Token_Kind,
    lexeme : union {
        string,
        int,
        f32,
    },
    line, col: int,
    file: string
}

is_token :: proc (input: ^strings.Builder, preview: byte) -> (Token, bool) {
    return Token({}), false
}

peek :: proc(lexer: ^Lexer, length:int = 0) -> byte {
    if lexer.cursor+length >= len(lexer.input) do return 0
    return lexer.input[lexer.cursor+length]
}
advance :: proc(lexer: ^Lexer) ->  bool {
    if lexer.cursor+1 > len(lexer.input) do return false
    lexer.cursor += 1
    return true
}
skip_whitespace :: proc(lexer: ^Lexer) {
    c := peek(lexer,0)
    count := 0
    for c == ' ' || c == '\n' {
        if c == '\n' do lexer.lines += 1
        if !advance(lexer) do break
        c = peek(lexer)
        count += 1
        if count > MAX_DEPTH do break
    }
}

is_digit :: proc(a: byte) -> bool {
    return a == '0' ||
        a == '1' ||
        a == '2' ||
        a == '3' ||
        a == '4' ||
        a == '5' ||
        a == '6' ||
        a == '7' ||
        a == '8' ||
        a == '9'
}

is_char :: proc(a: byte) -> bool {
    return (65 <= int(a) && int(a) <= 90) || (97 <= int(a) && int(a) <= 172)
}

read_number :: proc(lexer: ^Lexer) -> Token {
    buffer := strings.builder_make()
    for is_digit(peek(lexer)) {
        strings.write_byte(&buffer, peek(lexer))
        if !advance(lexer) do break
    }
    return Token({kind=.NUMBER, lexeme=strings.to_string(buffer)})
}
read_identifier :: proc(lexer: ^Lexer) -> Token {
    buffer := strings.builder_make()
    for is_char(peek(lexer)) || peek(lexer) == '_' || is_digit(peek(lexer)) {
        strings.write_byte(&buffer, peek(lexer))
        if !advance(lexer) do break
    }
    
    val := strings.to_string(buffer)
    kind : Token_Kind = .IDENTIFER
    
    switch val {
    case "let": kind = .LET
    case "void": kind = .VOID
    case "int": kind = .INT
    case "float": kind = .FLOAT
    case "string": kind = .STRING_TYPE
    case "extern": kind = .EXTERN
    case "d": kind = .DOUBLE
    case "func": kind = .FUNC
    case "start": kind = .START
    case "end": kind = .END
    case "if": kind = .IF
    case "else": kind = .ELSE
    case "while": kind = .WHILE
    case "return": kind = .RETURN

    }

    return Token({kind=kind, lexeme=val})
}

read_string :: proc(lexer: ^Lexer) -> Token {
    advance(lexer)

    buffer := strings.builder_make()
    for peek(lexer) != '"' {
        strings.write_byte(&buffer, peek(lexer))
        if !advance(lexer) do break
    }

//    if peek(lexer) != '"' do panic(fmt.tprintf("Unexpected char, expected \", got %c", peek(lexer)))
    advance(lexer)
    return Token({kind=.STRING, lexeme=fmt.tprintf("\"%s\"", strings.to_string(buffer))})
}

read_token :: proc (lexer: ^Lexer) -> Token {
    tokens := make([dynamic]Token)

    skip_whitespace(lexer)
    c := peek(lexer)

    switch c {
    case '{':
        advance(lexer)
        return Token({kind=.START, lexeme="{"})
    case '}':
        advance(lexer)
        return Token({kind=.END, lexeme="}"})
    }

    if is_char(c)       do return read_identifier(lexer)
    else if is_digit(c) do return read_number(lexer)
    else if c == '"'    do return read_string(lexer)

    // we defer adnave after the if statements to advanve the switch
    defer advance(lexer)

    if c == '=' && peek(lexer,1) == '=' {
        advance(lexer)
        return Token({kind=.EQ, lexeme="=="})
    }
    if c == '>' && peek(lexer,1) == '=' {
        advance(lexer)
        return Token({kind=.GEQ, lexeme=">="})
    }
    if c == '<' && peek(lexer,1) == '=' {
        advance(lexer)
        return Token({kind=.LEQ, lexeme="<="})
    }



    lexeme := fmt.tprintf("%c",c)

    switch c {
    case '=': return Token({kind=.EQUAL, lexeme=lexeme})
    case ':': return Token({kind=.COLON, lexeme=lexeme})
    case ';': return Token({kind=.SEMICOLON, lexeme=lexeme})
    case '(': return Token({kind=.LPAR, lexeme=lexeme})
    case ')': return Token({kind=.RPAR, lexeme=lexeme})
    case '[': return Token({kind=.LB, lexeme=lexeme})
    case ']': return Token({kind=.RB, lexeme=lexeme})
    case '.': return Token({kind=.PUNCT, lexeme=lexeme})
    case ',': return Token({kind=.COMMA, lexeme=lexeme})
    case '+': return Token({kind=.PLUS, lexeme=lexeme})
    case '-': return Token({kind=.MINUS, lexeme=lexeme})
    case '*': return Token({kind=.MULT, lexeme=lexeme})
    case '/': return Token({kind=.DIVIDE, lexeme=lexeme})
    case '<': return Token({kind=.LESS, lexeme=lexeme})
    case '>': return Token({kind=.GREATER, lexeme=lexeme})

    }
    
    return Token({kind=.INVALID, lexeme=""})
}
