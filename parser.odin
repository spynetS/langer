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

Program :: struct {
    functions: [dynamic]Function_Decl,
    variables: [dynamic]Variable_Decl
}

Variable_Decl :: struct {
    name: string,
    type: string,
    initlizer: ^Expr,    
}

Function_Decl :: struct {
    name: string,
    type: string,
    args: [dynamic]Variable_Decl,
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
    Function_Decl,
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
    program: ^Program,
    file: string
}

parser_panic :: proc(token: Token, error: string) {
    fmt.println(fmt.tprintf("{}:{}:{}: {}",token.file, token.line, token.col-2, error))
    panic("")
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
    if none do parser_panic(parser_peek(p),fmt.tprintf("Got unexpected token. Got '%s' wanted '%s'", token.kind, strings.to_string(s_kinds)))

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
    parser_panic(parser_peek(p),fmt.tprintf("Unexpected token {}", next_token.kind))
    return nil
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

check_function_call :: proc (p: ^Parser, call: Expr_Call) {
    didnt_find_fund := true
    for func in p.program.functions {
        if func.name == call.name {
            didnt_find_fund = false
            if len(func.args) != len(call.args) {
                parser_panic(parser_peek(p),fmt.tprintf("Function calls arguments {} doesnt match function declerations {}", len(func.args), len(call.args)))
            }
        }
    }
    // TODO, currently we rely in hardcoded libc functions like printf
    //if didnt_find_fund do parser_panic(parser_peek(p),fmt.tprintf("Func {} hasnt been declared", call.name))

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
            call := Expr_Call({
                name = expr.value,
                args = arguments
                
            })
            check_function_call(p, call)
            parser_skip(p, .RPAR, depth=0)
            //parser_advance(p)
            fmt.println("AFTER CALL PEEK", parser_peek(p))
            new_expr := new(Expr)
            new_expr^ = call
            return new_expr
        case Expr_String:
            parser_panic(parser_peek(p),"Expected identifer, got STRING")
        case Expr_Integer:
            parser_panic(parser_peek(p),"Expected identifer, got INT")
        case Expr_Binary:
            parser_panic(parser_peek(p),"Expected identifer, got BIN")
        case Expr_Call:
            parser_panic(parser_peek(p),"Expected identifer, got CALL")
        }

    }
    return left
}
    
parser_skip :: proc (p: ^Parser, kind: Token_Kind, depth: int = MAX_DEPTH) -> Token {
    token := parser_peek(p)
    count := 0
    for parser_peek(p).kind == kind {
        fmt.println("SKIPING", token.kind)
        token = parser_advance(p)
        count += 1
        if count > depth do break
    }
    return token
}

parse_expression :: proc (p: ^Parser) -> ^Expr {
    left := parse_term(p)
    fmt.println("== LEFT expr IS ===")
    print_expr(left^)
    fmt.println("== ======= ===")

    if parser_peek(p).kind == Token_Kind.PLUS ||
        parser_peek(p).kind == Token_Kind.MINUS ||
        parser_peek(p).kind == Token_Kind.EQUAL ||
        parser_peek(p).kind == Token_Kind.GREATER ||
        parser_peek(p).kind == Token_Kind.LESS ||
        parser_peek(p).kind == Token_Kind.EQ ||
        parser_peek(p).kind == Token_Kind.LEQ ||
        parser_peek(p).kind == Token_Kind.GEQ
    {
            op := parser_advance(p).kind
            fmt.println("===PARSING RIGHT===")
            right := parse_expression(p)
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
        //parser_panic(parser_peek(p),fmt.tprintf("Unexpected token, got {}", parser_peek(p).kind))
        return left
    }

    return left
}

is_decl :: proc (kind: Token_Kind) -> bool {
    #partial switch kind { case .INT, .FLOAT, .FUNC: return true }
    return false
}

parse_block :: proc(p: ^Parser) -> ^Block {
    fmt.println("parsing block")
    fmt.println("LOOKING FOR START")
    parser_expect(p, .START)
    block := new(Block)

    fmt.println("FOUND START")
    for parser_peek(p).kind != .END {
        if is_decl(parser_peek(p).kind) do append(&block.items, parse_decl(p))
        else do append(&block.items, parse_stmt(p))
        fmt.println("next stmt in block is", parser_peek(p).kind)
    }
    parser_expect(p, .END) // We consume end
    fmt.println("block done")
    return block
}

parse_if :: proc(p: ^Parser) -> ^If_Stmt {

    condition := parse_expression(p)
    fmt.println("===IF-CONDITION===")
    print_expr(condition^)
    stmt := new(If_Stmt)
    stmt.condition = condition
    
    block := parse_block(p)
    fmt.println("===IF-BLOCK===")
    print_block(block^)
    stmt.block = block


    if parser_peek(p).kind == .ELSE {
        parser_advance(p)
        else_block := parse_block(p)
        fmt.println("===ELSE-BLOCK===")
        print_block(else_block^)
        stmt.else_block = else_block
    }

    return stmt    
}

parse_return :: proc(p: ^Parser) -> ^Return_Stmt {
    ret := new(Return_Stmt)
    ret.value = parse_expression(p)
    return ret
}

is_type :: proc (kind: Token_Kind) -> bool {
    #partial switch kind {
    case .INT, .FLOAT: return true
    }
    return false
}

parse_func_decl :: proc(p: ^Parser) -> Function_Decl {
    decl := Function_Decl({})
    parser_skip(p, .FUNC)
    token := parser_expect(p, .IDENTIFER)
    decl.name = token.lexeme.(string)
    
    // args := parse_args(p)
    // for arg in args do print_expr(arg^)
    // decl.args = args

    decl.args = make([dynamic]Variable_Decl)
    parser_skip(p, .LPAR,depth=1)
    for parser_peek(p).kind != .RPAR {
        token := parser_advance(p)
        if is_type(token.kind) {
            fmt.println("IS DELC", token)
            var := Variable_Decl({type=token.lexeme.(string)})
            var.name = parser_expect(p, .IDENTIFER).lexeme.(string)
            append(&decl.args, var)
        }
    }

    for arg in decl.args do fmt.println(arg)

    fmt.println(parser_advance(p))
    // fmt.println(parser_advance(p))

    block := parse_block(p)
    print_block(block^)

    decl.block = block^;
    decl.type="void" // FIXME

    return decl
}


parse_variable_decl :: proc(p: ^Parser) -> Variable_Decl {
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
            fmt.println(parser_peek(p))
            parser_skip(p, .SEMICOLON)
            //parser_advance(p)
            return decl
        }
    }
    parser_panic(parser_peek(p),"This is not how you declare a variable. Should be int x = 10;")
    return Variable_Decl({})
}

parse_decl :: proc(p: ^Parser) -> Decl {
    token := parser_advance(p)
    decl := Decl({})
    #partial switch token.kind {
        case .INT, .FLOAT:
        p.pos -= 1 // to go back so peek is on int
        fmt.println("parsing int decl")
        decl = parse_variable_decl(p)
        case .FUNC:
        fmt.println("parsing func decl")
        decl = parse_func_decl(p)
    }
    parser_skip(p, .SEMICOLON)
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

parse_program :: proc(p: ^Parser) -> Program {
    token := parser_advance(p);
    p.program = new(Program)
    for parser_peek(p).kind != .EOF  {
        #partial switch token.kind {
            case .FUNC:
            p.pos -= 1
            func := parse_func_decl(p)
            fmt.println("===FUNC===")
            fmt.println(func.name)
            
            append(&p.program.functions, func)
        }
        parser_skip(p, .END)
        parser_advance(p)
    }
    return p.program^

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
            case Function_Decl:
                fmt.println("DECL func", decl.type, decl.name,)
            case Variable_Decl:
                fmt.println("DECL", decl.type, decl.name, "=", decl.initlizer)
            }
        case Stmt:
            fmt.print("STMT ")
            print_stmt(item)
            
        }
    }

}

print_program :: proc(program: Program) {
    fmt.println("program\n functions")
    for func in program.functions {
        fmt.println(func.name)
        //for arg in func.args do print_expr(arg^)
    }
}
