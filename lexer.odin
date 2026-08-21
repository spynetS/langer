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
    lines: int,
    col: int,
    file: string
}


Token_Kind :: enum {
    INVALID,
    EXTERN,
    FOR,
    NUMBER,
    EQUAL,
    COLON,
    SEMICOLON,
    IDENTIFER,
    STRING,
    STRING_LITERAL,
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
    STAR,
    DIVIDE,
    PUNCT,
    COMMA,
    AMPER,
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
    RB,

}

Source_Pos :: struct {
    file: string,
    line: int,
    col:  int,
}

Source_Span :: struct {
    start: Source_Pos,
    end:   Source_Pos,
}

Token :: struct {
    span: Source_Span,
    kind : Token_Kind,
    lexeme : string,
}

is_token :: proc (input: ^strings.Builder, preview: byte) -> (Token, bool) {
    return Token({}), false
}

peek :: proc(lexer: ^Lexer, length:int = 0) -> byte {
    if lexer.cursor+length >= len(lexer.input) do return 0
    return lexer.input[lexer.cursor+length]
}
advance :: proc(lexer: ^Lexer) -> bool {
    if lexer.cursor >= len(lexer.input) {
        return false
    }

    if lexer.input[lexer.cursor] == '\n' {
        lexer.lines += 1
        lexer.col = 1
    } else {
        lexer.col += 1
    }

    lexer.cursor += 1
    return true
}
skip_whitespace :: proc(lexer: ^Lexer) {
    c := peek(lexer,0)
    count := 0
    for c == ' ' || c == '\n' {
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
    // KEYWORDS
    switch val {
    case "for": kind = .FOR
    case "let": kind = .LET
    case "void": kind = .VOID
    case "int": kind = .INT
    case "float": kind = .FLOAT
    case "string": kind = .STRING
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
    return Token({kind=.STRING_LITERAL, lexeme=fmt.tprintf("\"%s\"", strings.to_string(buffer))})
}

// create_token :: proc (kind: Token_Kind, lexeme: string) -> Token {
    
// }

read_token :: proc (lexer: ^Lexer) -> Token {

    skip_whitespace(lexer)
    c := peek(lexer)

    token := Token({kind=.INVALID, lexeme=""})

    start := Source_Pos{
        col=lexer.col,
        line=lexer.lines,
        file=lexer.file
    }
    
    if c == '{' {
        advance(lexer)
        token = Token({kind=.START, lexeme="{"})
    }
    else if c== '}' {
        advance(lexer)
        token = Token({kind=.END, lexeme="}"})
    }
    else if is_char(c)  do token = read_identifier(lexer)
    else if is_digit(c) do token = read_number(lexer)
    else if c == '"'    do token = read_string(lexer)
    else if c == '=' && peek(lexer,1) == '=' {
        advance(lexer)
        token = Token({kind=.EQ, lexeme="=="})
    }
    else if c == '>' && peek(lexer,1) == '=' {
        advance(lexer)
        token = Token({kind=.GEQ, lexeme=">="})
    }
    else if c == '<' && peek(lexer,1) == '=' {
        advance(lexer)
        token = Token({kind=.LEQ, lexeme="<="})
    }
    else {
        lexeme := fmt.tprintf("%c",c)
        switch c {
        case '=': token = Token({kind=.EQUAL, lexeme=lexeme})
        case ':': token = Token({kind=.COLON, lexeme=lexeme})
        case ';': token = Token({kind=.SEMICOLON, lexeme=lexeme})
        case '(': token = Token({kind=.LPAR, lexeme=lexeme})
        case ')': token = Token({kind=.RPAR, lexeme=lexeme})
        case '[': token = Token({kind=.LB, lexeme=lexeme})
        case ']': token = Token({kind=.RB, lexeme=lexeme})
        case '.': token = Token({kind=.PUNCT, lexeme=lexeme})
        case ',': token = Token({kind=.COMMA, lexeme=lexeme})
        case '+': token = Token({kind=.PLUS, lexeme=lexeme})
        case '-': token = Token({kind=.MINUS, lexeme=lexeme})
        case '*': token = Token({kind=.STAR, lexeme=lexeme})
        case '/': token = Token({kind=.DIVIDE, lexeme=lexeme})
        case '<': token = Token({kind=.LESS, lexeme=lexeme})
        case '>': token = Token({kind=.GREATER, lexeme=lexeme})
        case '&': token = Token({kind=.AMPER, lexeme=lexeme})
        }
        advance(lexer)
    }
    token.span.start = start
    token.span.end = Source_Pos{
        col=lexer.col,
        line=lexer.lines,
        file=lexer.file
    }

    return token
}
