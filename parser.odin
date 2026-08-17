package main;
import "core:fmt"
import "core:strings"

/*
Expression → produces a value
Statement  → does something
Block      → contains statements
Function   → contains a block
Program    → contains top-level declarations
*/

Variable_Decl :: struct {
    name: string,
    type: string,
    initlizer: ^Expr,    
}

Function_Decl :: struct {
    name: string,
    type: string,
    args: [dynamic]^Expr,
    block: Block
}

If_Stmt :: struct {
    condition: ^Expr,
    block: ^Block,
    else_block: ^Block,
}
While_Stmt :: struct {
    condition: ^Expr,
    block: Block,   
}

BlockItem :: union {
    Decl,
    Stmt,
}

Block :: struct {
    items: [dynamic]BlockItem,
}
Return_Stmt :: struct {
    value: ^Expr,
}

Decl :: union {
    Variable_Decl,
}

Stmt :: union {
    Expr,
    Return_Stmt,
    If_Stmt,
    While_Stmt,
    Block,
}

Expr_Kind :: enum {
    Integer,
    Identifier,
    Binary,
    Unary,
    Call,
}

Expr_Integer :: struct {
    value: string,
}
Expr_String :: struct {
    value: string,
}
Expr_Identifier :: struct {
    value: string,
}
Expr_Binary :: struct {
    op: Token_Kind,
    left: ^Expr,
    right: ^Expr
}
Expr_Call :: struct {
    name: string,
    args: [dynamic]^Expr
}

Expr :: union {
    Expr_Integer,
    Expr_String,
    Expr_Identifier,
    Expr_Binary,
    Expr_Call,
}

Parser :: struct {
    tokens: [dynamic]Token,
    pos:    int,
}

parser_next :: proc(p: ^Parser, amnt: int = 1) -> (Token, bool) #optional_ok {
    if p.pos+amnt >= len(p.tokens) do return Token({}), false
    return p.tokens[p.pos+amnt], true
}

parser_peek :: proc(p: ^Parser) -> (Token, bool) #optional_ok {
    if p.pos >= len(p.tokens) do return Token({}), false
    return p.tokens[p.pos], true
}

parser_advance :: proc(p: ^Parser) -> (Token, bool) #optional_ok {
    token, ok := parser_peek(p)
    if !ok do return token, false
    p.pos += 1
    return token, true
}

parser_expect :: proc(p: ^Parser, kinds: ..Token_Kind) -> Token {
    token := parser_peek(p)
    none := true
    s_kinds := strings.builder_make()
    for kind in kinds {
        strings.write_string(&s_kinds, fmt.tprintf("%s",kind))
        strings.write_string(&s_kinds, ",")
        if token.kind == kind {
            // syntax error
            none = false
        }
    }
    if none do  panic(fmt.tprintf("Got unexpected token. Got '%s' wanted '%s'", token.kind, strings.to_string(s_kinds)))

    return parser_advance(p)
}

parse_factor :: proc(p: ^Parser) -> ^Expr {
    next_token := parser_advance(p)
    fmt.println("parsing factor: ", next_token)
    #partial switch next_token.kind {
        case .STRING:
        expr := new(Expr)
        expr^ = Expr_String{
            value = next_token.lexeme.(string),
        }
        return expr
    case .NUMBER:
        expr := new(Expr)
        expr^ = Expr_Integer{
            value = next_token.lexeme.(string),
        }
        return expr
    case .LPAR:
        fmt.println("found param, parsing expression")
        expr := parse_expression(p)
        parser_expect(p, .RPAR)
        fmt.println("found expr", expr)
        return expr
        case .IDENTIFER:
        expr := new(Expr)
        expr^ = Expr_Identifier{
            value = next_token.lexeme.(string),
        }

        return expr
        case .COMMA:
        
    case .RPAR:
        fmt.println("found right param, expression done")
        return nil
    }
    panic(fmt.tprintf("Unexpected token {}", next_token.kind))
}

parse_args :: proc(p: ^Parser) -> [dynamic]^Expr {
    args := make([dynamic]^Expr)
    parser_expect(p,.LPAR)
    first := true
    for parser_peek(p).kind != .RPAR {
        if !first do parser_expect(p, .COMMA)
        else      do first = false
        fmt.println("parsing next arg")
        expr := parse_expression(p)
        fmt.println("ARG:",expr)
        append(&args, expr)
    }

    return args
}

parse_term :: proc(p: ^Parser) -> ^Expr {

    left := parse_factor(p)
    if parser_peek(p).kind == Token_Kind.MULT ||
        parser_peek(p).kind == Token_Kind.DIVIDE
    {
        op := parser_advance(p).kind
        right := parse_factor(p)
        expr := new(Expr)
        expr^ = Expr_Binary({
            left = left,
            right = right,
            op = op
        })

        return expr
    }
    else if parser_peek(p).kind == .COMMA { // we are done
        return left
    }
    else if parser_peek(p).kind == .LPAR { // we are a function call
        fmt.println("=== PARSING FUNCTION CALL ====")
        switch expr in left^ {
            case Expr_Identifier:
            arguments := parse_args(p)
            new_expr := new(Expr)
            new_expr^ = Expr_Call({
                name = expr.value,
                args = arguments
                
            })
            return new_expr
        case Expr_String:
            panic("Expected identifer, got STRING")
        case Expr_Integer:
            panic("Expected identifer, got INT")
        case Expr_Binary:
            panic("Expected identifer, got BIN")
        case Expr_Call:
            panic("Expected identifer, got CALL")
        }

    }
    return left
}
    
parser_skip :: proc (p: ^Parser, kind: Token_Kind) -> Token {
    token := parser_peek(p)
    count := 0
    for token.kind == kind {
        token = parser_advance(p)
        count += 1
        if count > MAX_DEPTH do break
    }
    return token
}

parse_expression :: proc (p: ^Parser) -> ^Expr {
    left := parse_term(p)
    fmt.println("== LEFT IS ===")
    print_expr(left^)
    fmt.println("== ======= ===")

    if parser_peek(p).kind == Token_Kind.PLUS ||
        parser_peek(p).kind == Token_Kind.MINUS ||
        parser_peek(p).kind == Token_Kind.EQUAL ||
        parser_peek(p).kind == Token_Kind.GREATER ||
        parser_peek(p).kind == Token_Kind.LESS {
            op := parser_advance(p).kind
            
            right := parse_term(p)
            fmt.println("== RIGHT IS ===")
            print_expr(right^)
            fmt.println("== ======= ===")
            
            expr := new(Expr)
            expr^ = Expr_Binary({
                left=left,
                right=right,
                op=op
            })
            return expr
        }
    else if parser_peek(p).kind == .COMMA {}
    else if parser_peek(p).kind == .RPAR {}
    else if parser_peek(p).kind != .SEMICOLON {
        panic(fmt.tprintf("Unexpected token, got {}, wanted ;", parser_peek(p).kind))
    }

    return left
}

is_decl :: proc (kind: Token_Kind) -> bool {
    #partial switch kind { case .INT, .FLOAT, .FUNC: return true }
    return false
}

parse_block :: proc(p: ^Parser) -> ^Block {
    fmt.println("LOOKING FOR START")
    parser_expect(p, .START)
    block := new(Block)

    fmt.println("FOUND START")
    for parser_peek(p).kind != .END {
        if is_decl(parser_peek(p).kind) do append(&block.items, parse_decl(p))
        else do append(&block.items, parse_stmt(p))
        p.pos -= 1
        fmt.println("next stmt in block is", parser_peek(p).kind)
    }

    return block
}

parse_if :: proc(p: ^Parser) -> ^If_Stmt {
    condition := parse_expression(p)
    fmt.println("===IF-CONDITION===")
    print_expr(condition^)
    
    block := parse_block(p)
    fmt.println("===block===")
    print_block(block^)
    stmt := new(If_Stmt)
    stmt.condition = condition
    stmt.block = block
    return stmt    
}

parse_return :: proc(p: ^Parser) -> ^Return_Stmt {
    ret := new(Return_Stmt)
    ret.value = parse_expression(p)
    return ret
}

parse_func_decl :: proc(p: ^Parser) -> Decl {
    decl := Function_Decl({})
    
    panic("Functions not implemeted yet. (We dont need them)")
}


parse_variable_decl :: proc(p: ^Parser) -> Decl {
    decl := Variable_Decl({})
    token := parser_advance(p)
    decl.type = token.lexeme.(string)
    // we advance one more step after getting the type
    token = parser_advance(p)
    if token.kind == .IDENTIFER {
        decl.name = token.lexeme.(string)
        token = parser_advance(p)
        if token.kind == .EQUAL {
            init := parse_expression(p)
            fmt.println("init is", init)
            decl.initlizer = init
            parser_expect(p, .SEMICOLON)
            parser_advance(p)
            return decl
        }
    }
    panic("This is not how you declare a variable. Should be int x = 10;")
}

parse_decl :: proc(p: ^Parser) -> Decl {
    token := parser_advance(p)
    decl := Decl({})
    #partial switch token.kind {
        case .INT, .FLOAT:
        p.pos -= 1 // to go back so peek is on int
        fmt.println("parsing int decl")
        return parse_variable_decl(p)
        case .FUNC:
        fmt.println("parsing func decl")
        return parse_func_decl(p)
    }
    return decl
}

parse_stmt :: proc(p: ^Parser) -> Stmt {
    token := parser_advance(p)
    stmt := Stmt({})
    fmt.println("stmt next is ", parser_next(p).kind)
    #partial switch parser_next(p).kind {
        case .EQUAL:
        fmt.println("assigment")
    }


    #partial switch token.kind {
        case .IF:
        fmt.println("parsing if stmt")
        stmt = parse_if(p)^;
        case .RETURN:
        fmt.println("parsing return stmt")
        stmt = parse_return(p)^
        case:
        p.pos -= 1
        fmt.println("parsing other stmt")
        fmt.println("PARSING-EXPR:", parser_peek(p).kind)
        expr := parse_expression(p)
        if expr == nil do break
        print_expr(expr^)
        parser_skip(p, .RPAR)
        stmt = expr^
    }

 


    parser_skip(p,.SEMICOLON)
    return stmt
}

print_expr :: proc(expr_u: Expr, depth: int = 0) {
    for _ in 0..<depth {
        fmt.print("  ")
    }

    #partial switch expr in expr_u {
    case Expr_Binary:
        fmt.println("Binary ", expr.op)
        print_expr(expr.left^, depth + 1)
        print_expr(expr.right^, depth + 1)

    case Expr_Integer:
        fmt.println("Integer ", expr.value)
    case Expr_Call:
        fmt.println("Call \n", expr.name)
        for arg in expr.args {
            print_expr(arg^, depth+1)
        }
    case Expr_String:
        fmt.println("String ", expr.value)
    case Expr_Identifier:
        fmt.println("Identifier ", expr.value)
    }
}

print_stmt :: proc (stmt: Stmt) {
    #partial switch v in stmt {
        case Expr: print_expr(v)
        case Return_Stmt:
        fmt.println("RETURN")
        print_expr(v.value^)
        case If_Stmt:
        fmt.println("IF")
        print_expr(v.condition^)
        fmt.println("")
        print_block(v.block^)
    }

}

print_block :: proc(block: Block) {
    for item_u in block.items {
        switch item in item_u {
        case Decl:
            switch decl in item {
            case Variable_Decl:
                fmt.println("DECL", decl.type, decl.name, "=", decl.initlizer)
            }
        case Stmt:
            fmt.print("STMT ")
            print_stmt(item)
            
        }
    }

}
