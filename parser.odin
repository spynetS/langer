package main;
import "core:fmt"

/*
Expression → produces a value
Statement  → does something
Block      → contains statements
Function   → contains a block
Program    → contains top-level declarations
*/

Stmt_Kind :: enum {
    Variable_Decl,
    Expression,
    Return,
    If,
    While,
    Block,
}

Variable_Decl :: struct {
    name: string,
    type: string,
    initlizer: string,    
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
Block :: struct {
    statements: [dynamic]Stmt,
}
Return_Stmt :: struct {
    value: ^Expr,
}

Stmt :: union {
    Variable_Decl,
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
// 10 + 10, (10+10)+10  10+10*2
Expr :: struct {
    kind: Expr_Kind,

    value: string,

    op: Token_Kind,
    left: ^Expr,
    right: ^Expr,
}

Parser :: struct {
    tokens: [dynamic]Token,
    pos:    int,
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

parser_expect :: proc(p: ^Parser, kind: Token_Kind) -> Token {
    token := parser_peek(p)

    if token.kind != kind {
        // syntax error
        panic(fmt.tprintf("Got unexpected token. Got '%s' wanted '%s'", token.kind, kind))
    }

    return parser_advance(p)
}

parse_factor :: proc(p: ^Parser) -> ^Expr {
    expr := new(Expr)
    next_token := parser_advance(p)
    fmt.println("parsing factor: ", next_token)
    #partial switch next_token.kind {
    case .NUMBER:
        expr.kind = .Integer
        expr.value = next_token.lexeme.(string)
        return expr
    case .LPAR:
        fmt.println("found param, parsing expression")
        free(expr)
        expr = parse_expression(p)
        parser_expect(p, .RPAR)
        fmt.println("found expr", expr)
        return expr
        case .IDENTIFER:
        expr.kind = .Identifier
        expr.value = next_token.lexeme.(string)
        case .RPAR:
        fmt.println("found right param, expression done")
        return expr
    }
    free(expr)
    return nil
}

parse_term :: proc(p: ^Parser) -> ^Expr {

    left := parse_factor(p)
    if left == nil do return nil
    
    if parser_peek(p).kind == Token_Kind.MULT || parser_peek(p).kind == Token_Kind.DIVIDE {
        op := parser_advance(p).kind
        
        right := parse_factor(p)
        if right == nil do return nil
    
        expr := new(Expr)
        expr.kind = Expr_Kind.Binary
        expr.left = left
        expr.right = right
        expr.op = op
        return expr
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
        parser_peek(p).kind == Token_Kind.GREATER ||
        parser_peek(p).kind == Token_Kind.LESS {
            op := parser_advance(p).kind
            
            right := parse_term(p)
            fmt.println("== RIGHT IS ===")
            print_expr(right^)
            fmt.println("== ======= ===")
            
        expr := new(Expr)
        expr.kind = Expr_Kind.Binary
        expr.left = left
        expr.right = right
        expr.op = op
        return expr
        }
    else if parser_peek(p).kind != .SEMICOLON {
        panic(fmt.tprintf("Unexpected token, got {}", parser_peek(p).kind))
    }
    return left
}
parse_block :: proc(p: ^Parser) -> ^Block {
    fmt.println("LOOKING FOR START")
    parser_expect(p, .START)
    block := new(Block)
    fmt.println("FOUND START")
    append(&block.statements, parse_stmt(p))
    fmt.println("check for end")
    p.pos -= 1
    parser_expect(p, .END)

    return block
}

parse_if :: proc(p: ^Parser) -> ^If_Stmt {
    condition := parse_expression(p)
    fmt.println("IF-CONDITION: ", condition)
    
    block := parse_block(p)
    
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

parse_stmt :: proc(p: ^Parser) -> Stmt {
    token := parser_advance(p)
    stmt := Stmt({})
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

print_expr :: proc(expr: Expr, depth: int = 0) {
    for _ in 0..<depth {
        fmt.print("  ")
    }

    #partial switch expr.kind {
    case .Binary:
        fmt.println("Binary ", expr.op)
        print_expr(expr.left^, depth + 1)
        print_expr(expr.right^, depth + 1)

    case .Integer:
        fmt.println("Integer ", expr.value)

    case .Identifier:
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
        for stmt in v.block.statements {
            fmt.println("block statement")
            print_stmt(stmt)
        }
    }

}
