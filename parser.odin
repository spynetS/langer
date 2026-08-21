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
    extern   : [dynamic]string,
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
    block: ^Block,
    extern: bool
}

If_Stmt :: struct {
    condition: ^Expr,
    block: ^Block,
    else_block: ^Block,
}
While_Stmt :: struct {
    condition: ^Expr,
    block: ^Block,   
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
Expr_Array :: struct {
    values: [dynamic]^Expr
}
Expr_Subscript :: struct {
    left: ^Expr_Identifier,
    index: ^Expr,
    type: string // TODO ptr or array
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
    Expr_Array,
    Expr_Subscript,
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

log_error :: proc (str : string) {
    fmt.println(str)
}

parser_panic :: proc(token: Token, error: string) {
    log_error(fmt.tprintf("{}:{}:{}: {}",token.file, token.line, token.col-2, error))
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

parser_expect :: proc(p: ^Parser, kinds: ..Token_Kind, custom_msg: string = "") -> Token {
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
    if none do parser_panic(token,fmt.tprintf("Got unexpected token. Got '%s' wanted '%s'\n %s", token.kind, strings.to_string(s_kinds), custom_msg))

    return parser_advance(p)
}

parse_factor :: proc(p: ^Parser) -> ^Expr {
    next_token := parser_advance(p)
    logln("parsing factor: ", next_token)
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
        logln("found param, parsing expression")
        expr := parse_expression(p)
        parser_expect(p, .RPAR)
        logln("found expr", expr)
        return expr
        case .IDENTIFER:
        expr := new(Expr)
        expr^ = Expr_Identifier{
            value = next_token.lexeme.(string),
        }

        return expr
        case .COMMA:
        
    case .RPAR:
        logln("found right param, expression done")
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
        logln("parsing next arg")
        expr := parse_expression(p)
        logln("ARG:",expr)
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
                parser_panic(parser_peek(p),fmt.tprintf("Function calls arguments {} doesnt match function declerations {}", len(call.args), len(func.args)))
            }
            for i in 0..<len(func.args) {
                arg_type := get_expr_type(p, call.args[i])
                if arg_type == "" do continue
                if func.args[i].type != arg_type {
                    parser_panic(parser_peek(p),fmt.tprintf("Call parameter types ({}) doesn't match function decleration type ({})", arg_type,func.args[i].type))
                }
            }

        }
    }
    // TODO, currently we rely in hardcoded libc functions like printf
    if didnt_find_fund do parser_panic(parser_peek(p),fmt.tprintf("Func {} hasnt been declared", call.name))
}

parse_array_init :: proc(p: ^Parser) -> Expr_Array {
    parser_expect(p, .START, custom_msg="Array initliztion should be: let arr: []int = {0,1,2,3}")
    
    expr := Expr_Array({})
    for parser_peek(p).kind != .END {
        val_expr := parse_expression(p)
        append(&expr.values,val_expr)
        parser_skip(p, .COMMA)
    }
    parser_advance(p)
    parser_skip(p, .SEMICOLON)
    return expr
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
    else if parser_peek(p).kind == .LB { // we are SUB
        parser_advance(p)
        index := parse_expression(p)
        left_id := new(Expr_Identifier)
        left_id = cast(^Expr_Identifier)left
        sub := new(Expr)
        sub^ = Expr_Subscript({
            left = left_id,
            index = index
        })
        parser_skip(p, .RB)
        parser_skip(p, .SEMICOLON)
        return sub
    }
    else if parser_peek(p).kind == .COMMA { // we are done
        return left
    }
    else if parser_peek(p).kind == .LPAR { // we are a function call
        logln("=== PARSING FUNCTION CALL ====")
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
            logln("AFTER CALL PEEK", parser_peek(p))
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
        case Expr_Array:
            parser_panic(parser_peek(p),"Expected identifer, got ARRAY")
        case Expr_Subscript:
            parser_panic(parser_peek(p),"Expected identifer, got Subscript")
        }

    }
    return left
}
    
parser_skip :: proc (p: ^Parser, kind: Token_Kind, depth: int = MAX_DEPTH) -> Token {
    token := parser_peek(p)
    count := 0
    for parser_peek(p).kind == kind {
        logln("SKIPING", token.kind)
        token = parser_advance(p)
        count += 1
        if count > depth do break
    }
    return token
}

parse_expression :: proc (p: ^Parser) -> ^Expr {
    left := parse_term(p)
    logln("== LEFT expr IS ===")
    print_expr(left^)
    logln("== ======= ===")

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
            logln("===PARSING RIGHT===")
            right := parse_expression(p)
            logln("== RIGHT IS ===")
            print_expr(right^)
            logln("== ======= ===")
            
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
    if is_type(kind) do return true
    else if kind == .FUNC do return true
    else if kind == .LET do return true
    return false
}

find_var :: proc(p: ^Parser, ident: Expr_Identifier) {

}

get_expr_type :: proc(p: ^Parser, expr: ^Expr) -> string {
    #partial switch value in expr {
        case Expr_Identifier, Expr_Subscript: return ""
        case Expr_Array:
        return get_expr_type(p, value.values[0])
        case Expr_Integer: return "int"
        case Expr_String:  return "string"
        case Expr_Binary:  return get_expr_type(p, value.left)
        case Expr_Call:
        for func in p.program.functions {
            if value.name == func.name {
                return func.type
            }
        }
    }
    panic("TODO")
}

check_return_type :: proc(p: ^Parser, return_value: ^Expr, return_type: string)  {
    return_type := strings.to_lower(return_type)
    #partial switch value in return_value {
        case Expr_Integer: if return_type != "int"    do parser_panic(parser_peek(p), fmt.tprintfln("return type missmatch with function %s != %s", return_type, "int"))
        case Expr_String:  if return_type != "string" do parser_panic(parser_peek(p),  fmt.tprintfln("return type missmatch with function %s != %s", return_type, "string"))
    case Expr_Binary:
        check_return_type(p, value.left, return_type)
        check_return_type(p, value.right, return_type)
    case Expr_Call:
        for func in p.program.functions {
            if value.name == func.name {
                if func.type != return_type       do parser_panic(parser_peek(p),  fmt.tprintfln("return type missmatch with function %s != %s", return_type, func.type))
            }
        }
        
    }
}

parse_block :: proc(p: ^Parser, return_type: string = "") -> ^Block {
    logln("parsing block")
    logln("LOOKING FOR START")
    parser_expect(p, .START)
    block := new(Block)

    logln("FOUND START")
    for parser_peek(p).kind != .END {
        if is_decl(parser_peek(p).kind) do append(&block.items, parse_decl(p))
        else {
            stmt := parse_stmt(p)
            #partial switch st in stmt {
                case Return_Stmt: check_return_type(p, st.value, return_type)
            }
            append(&block.items, stmt)
        }
        logln("next stmt in block is", parser_peek(p).kind)
    }
    parser_expect(p, .END) // We consume end
    logln("block done")
    return block
}

parse_if :: proc(p: ^Parser) -> ^If_Stmt {

    condition := parse_expression(p)
    logln("===IF-CONDITION===")
    print_expr(condition^)
    stmt := new(If_Stmt)
    stmt.condition = condition
    
    block := parse_block(p)
    logln("===IF-BLOCK===")
    print_block(block^)
    stmt.block = block


    if parser_peek(p).kind == .ELSE {
        parser_advance(p)
        else_block := parse_block(p)
        logln("===ELSE-BLOCK===")
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
        case .VOID, .INT, .FLOAT, .STRING_TYPE: return true
    }
    return false
}

parse_func_decl :: proc(p: ^Parser) -> Function_Decl {
        decl := Function_Decl({})
    parser_skip(p, .FUNC)
    logln("PEEK:",parser_peek(p))
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
            logln("IS DELC", token)
            var := Variable_Decl({type=token.lexeme.(string)})
            var.name = parser_expect(p, .IDENTIFER).lexeme.(string)
            append(&decl.args, var)
        }
    }

    for arg in decl.args do logln(arg)
    parser_skip(p, .RPAR,depth=1)

    if parser_peek(p).kind == .COLON {
        logln(parser_advance(p))
        t := parser_advance(p)
        if !is_type(t.kind) do parser_panic(t, fmt.tprintf("'%s' is not a type", t.lexeme.(string)))
        decl.type = t.lexeme.(string)
    }

    return decl
}

parse_func :: proc(p: ^Parser) -> Function_Decl {
    decl := parse_func_decl(p)

    block := parse_block(p, decl.type)
    print_block(block^)

    decl.block = block;

    return decl
}


parse_variable_decl :: proc(p: ^Parser) -> Variable_Decl {
    logln("parse Variable decl")
    decl := Variable_Decl({})
    parser_skip(p,.LET, depth=1)
    token := parser_advance(p)
    decl.name = token.lexeme.(string)
    logln(decl.type)
    parser_expect(p, .COLON, custom_msg = "Variable decleration: let age := 10; or let age: int = 10;");
    token = parser_advance(p)
    // check for type
    // if it is [ we should parse as array
    // of it is equal no type was specified so we try to guess
    if is_type(token.kind) {
        decl.type = fmt.tprintf("%s", token.kind)
        token = parser_advance(p)
    }
    else if  (token.kind == .LB && parser_peek(p).kind == .RB && is_type(parser_next(p).kind)) {
        parser_advance(p)
        decl.type = fmt.tprintf("%s_arr", parser_advance(p).kind)
        parser_expect(p,.EQUAL)

        expr := parse_array_init(p)
        token = parser_peek(p)

        decl.initlizer = new(Expr)
        decl.initlizer^ = expr
        return decl

    }
    else if token.kind == .EQUAL {
        pos := p.pos
        init : ^Expr
        // if it is start its an array init so we parse the array init
        // set the array init and the type and return
        // if it isnt array we just ges the type and continue
        if parser_peek(p).kind == .START {
            init = new(Expr)
            arr := parse_array_init(p)
            init^ = arr
            decl.initlizer = init
            decl.type = get_expr_type(p, init)
            return decl
        }
        else {
            init = parse_expression(p)
            decl.type = get_expr_type(p, init)
            p.pos = pos

        }
    }
    if token.kind == .EQUAL {
        init := parse_expression(p)
        logln("init is", init)
        decl.initlizer = init
        logln(parser_peek(p))
        parser_skip(p, .SEMICOLON)
        //parser_advance(p)
        return decl
    }

    parser_panic(parser_peek(p),"This is not how you declare a variable. Should be let x :int = 10;")
    return Variable_Decl({})
}

parse_decl :: proc(p: ^Parser) -> Decl {
    token := parser_advance(p)
    decl := Decl({})
    #partial switch token.kind {
        case .LET:
        p.pos -= 1 // to go back so peek is on int
        logln("parsing int decl")
        decl = parse_variable_decl(p)
        case .FUNC:
        logln("parsing func decl")
        decl = parse_func(p)
    }
    parser_skip(p, .SEMICOLON)
    return decl
}

parse_while :: proc(p: ^Parser) -> While_Stmt {
    condition := parse_expression(p)
    block := parse_block(p)

    return While_Stmt({
        condition = condition,
        block = block
    })
}


parse_stmt :: proc(p: ^Parser) -> Stmt {
    token := parser_advance(p)
    stmt := Stmt({})
    logln("stmt next is ", parser_next(p).kind)
    #partial switch parser_next(p).kind {
        case .EQUAL:
        logln("assigment")
    }


    #partial switch token.kind {
        case .WHILE:
        logln("parsing for stmt")
        stmt = parse_while(p);
        case .IF:
        logln("parsing if stmt")
        if_stmt := parse_if(p);
        stmt = if_stmt^;
        free(if_stmt)
        
        case .RETURN:
        logln("parsing return stmt")
        ret_stmt := parse_return(p)
        stmt = ret_stmt^;
        free(ret_stmt)
        case:
        p.pos -= 1
        logln("parsing other stmt")
        logln("PARSING-EXPR:", parser_peek(p).kind)
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
    p.program = new(Program)
    for parser_peek(p).kind != .EOF && parser_peek(p).kind != .INVALID  {
        logln(parser_peek(p))
        #partial switch parser_peek(p).kind {
            case .EXTERN:
            parser_advance(p)
            func := parse_func_decl(p)
            func.extern = true
            parser_skip(p, .SEMICOLON)
            append(&p.program.functions, func)            
            case .FUNC:
            func := parse_func(p)
            logln("===FUNC===")
            logln(func.name, func.args[:])
            print_block(func.block^)
            append(&p.program.functions, func)
        }
        logln("after prase", parser_peek(p))
    }
    return p.program^

}

print_indent :: proc(depth: int) {
    for _ in 0..<depth {
        log("  ")
    }
}

print_expr :: proc(expr_u: Expr, depth: int = 0) {
    print_indent(depth)

    #partial switch expr in expr_u {
    case Expr_Binary:
        logln("Binary ", expr.op)
        print_expr(expr.left^, depth + 1)
        print_expr(expr.right^, depth + 1)

    case Expr_Subscript:
        logln("Subscript")
        print_expr(expr.left^, depth + 1)
        print_expr(expr.index^, depth + 1)

    case Expr_Integer:
        logln("Integer: ", expr.value)

    case Expr_String:
        logln("String: \"", expr.value, "\"")

    case Expr_Identifier:
        logln("Identifier: ", expr.value)

    case Expr_Call:
        logln("Call: ", expr.name)
        for arg in expr.args {
            print_expr(arg^, depth + 1)
        }
    }
}

print_stmt :: proc(stmt: Stmt, depth: int = 0) {
    #partial switch v in stmt {
    case Expr:
        print_expr(v, depth)

    case Return_Stmt:
        print_indent(depth)
        logln("Return")
        print_expr(v.value^, depth + 1)

    case If_Stmt:
        print_indent(depth)
        logln("If")

        print_indent(depth + 1)
        logln("Condition")
        print_expr(v.condition^, depth + 2)

        print_indent(depth + 1)
        logln("Body")
        print_block(v.block^, depth + 2)
    }
}

print_decl :: proc(decl_u: Decl, depth: int = 0) {
    #partial switch decl in decl_u {
    case Function_Decl:
        print_indent(depth)
        logln("Function: ", decl.name)

        // If you have arguments:
        // print_indent(depth + 1)
        // logln("Arguments")
        // for arg in decl.args {
        //     print_expr(arg^, depth + 2)
        // }

        if decl.block != nil {
            print_block(decl.block^, depth + 1)
        }

    case Variable_Decl:
        print_indent(depth)
        logln("Variable: ", decl.name, " : ", decl.type)

        if decl.initlizer != nil {
            print_indent(depth + 1)
            logln("Initializer")
            print_expr(decl.initlizer^, depth + 2)
        }
    }
}

print_block :: proc(block: Block, depth: int = 0) {
    print_indent(depth)
    logln("Block")

    for item_u in block.items {
        #partial switch item in item_u {
        case Decl:
            print_decl(item, depth + 1)

        case Stmt:
            print_stmt(item, depth + 1)
        }
    }
}

print_program :: proc(program: Program) {
    logln("Program")

    for func in program.functions {
        print_decl(func, 1)
    }
}
