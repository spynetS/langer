package main;
import "core:fmt"
import "core:strings"
import "core:os"
import "core:mem"
import "core:strconv"

/*
Expression → produces a value
Statement  → does something
Block      → contains statements
Function   → contains a block
Program    → contains top-level declarations
*/

Parser :: struct {
    tokens: [dynamic]Token,
    pos:    int,
    package_: ^Package,
    file: string,
    current_block: ^Block
}

Program :: struct {
    packages : [dynamic]Package
}

Package :: struct {
    package_name: string,
    file: string,
    extern    : [dynamic]string,
    functions : [dynamic]Function_Decl,
    structs   : [dynamic]Struct_Decl,
    imports   : [dynamic]Import_Stmt,
}

Basic :: enum {
    INT,
    BYTE, // char
    BOOL,
    STRING,
    FLOAT,
    DOUBLE,
    VOID
}
NamedType :: struct {
    value: string
}
Array :: struct {
    of: ^Type,
    length: u64
}

Pointer :: struct {
    to: ^Type
}

Type :: union {
    Basic,
    Array,
    Pointer,
    Struct_Decl,
    NamedType
}

Variable_Decl :: struct {
    span: Source_Span,
    name: string,
    type: Type,
    initlizer: ^Expr    
}

Function_Decl :: struct {
    span: Source_Span,
    name: string,
    type: Type,
    args: [dynamic]Variable_Decl,
    block: ^Block,
    extern: bool
}

Struct_Decl :: struct {
    span: Source_Span,
    name: string,
    members: [dynamic]Variable_Decl,
}


If_Stmt :: struct {
    span: Source_Span,
    condition: ^Expr,
    block: ^Block,
    else_block: ^Block,
}
While_Stmt :: struct {
    span: Source_Span,
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
    type: Type,
    span: Source_Span,
}

Import_Stmt :: struct {
    value: ^Expr,
    span: Source_Span,
}

Decl :: union {
    Function_Decl,
    Variable_Decl,
    Struct_Decl
}

Stmt :: union {
    Expr,
    Return_Stmt,
    If_Stmt,
    While_Stmt,
    Block,
}

Expr_MemberAccess :: struct {
    obj: ^Expr,
    member: string,
    type: Type,
    span: Source_Span,
}

Expr_Unary :: struct {
    span: Source_Span,
    operator: Token_Kind,
    operand: ^Expr,
    type: Type
}
Expr_Array :: struct {
    span: Source_Span,
    values: [dynamic]^Expr
}
Expr_Subscript :: struct {
    span: Source_Span,
    left: ^Expr,
    index: ^Expr,
    type: Type // TODO ptr or array
}
Expr_Number :: struct {
    span: Source_Span,
    value: string,
    type: Type
}
Expr_String :: struct {
    span: Source_Span,
    value: string,
}
Expr_Identifier :: struct {
    span: Source_Span,
    value: string,
    type: Type
}
Expr_Binary :: struct {
    span: Source_Span,
    op: Token_Kind,
    left: ^Expr,
    right: ^Expr
}
Expr_Call :: struct {
    span: Source_Span,
    name: ^Expr,
    args: [dynamic]^Expr,
    type: Type
}

Expr :: union {
    Expr_MemberAccess,
    Expr_Array,
    Expr_Subscript,
    Expr_Number,
    Expr_String,
    Expr_Identifier,
    Expr_Binary,
    Expr_Call,
    Expr_Unary
}


/// ====== LOGGING ======
log_error :: proc (str : string) {
    fmt.println(str)

}
parser_panic :: proc {
    parser_panic_pos,    
    parser_panic_expr,
    parser_panic_expr_token,
    parser_panic_expr_parent,  
    parser_panic_decl,  
    parser_panic_decl_parent,  
    parser_panic_token,    
}

parser_panic_pos :: proc(span: Source_Span, error: string, level: int = 1) {
    str := fmt.tprintf("{}:{}:{}: {} {}",span.start.file, span.start.line, span.start.col, level==1 ? "error:" : "warning:", error)
    log_error(str)
    if level == 1 do panic("asd")
}

get_expr_span :: proc(expr: Expr) -> Source_Span {
    switch v in expr {
    case Expr_MemberAccess:
        return v.span
    case Expr_Array:
        return v.span
        case Expr_Subscript:
        return v.span
        case Expr_Number:
        return v.span
        case Expr_String:
        return v.span
        case Expr_Identifier:
        return v.span
        case Expr_Binary:
        return v.span
        case Expr_Call:
        return v.span
        case Expr_Unary:
        return v.span
    }
    panic("Not an expr")
}

decl_get_name :: proc(decl: Decl) -> string {
    switch v in decl {
    case Variable_Decl: return v.name
    case Function_Decl: return v.name
    case Struct_Decl: return v.name
    }
    panic("TODO")
}

decl_get_type :: proc(decl: Decl) -> Type {
    switch v in decl {
    case Variable_Decl: return v.type
    case Function_Decl: return v.type
    case Struct_Decl: panic("TODO")
    }
    fmt.println(decl)
    panic("TODO")
}

decl_get_span :: proc(decl: Decl) -> Source_Span {
    switch v in decl {
    case Variable_Decl: return v.span
    case Function_Decl: return v.span
    case Struct_Decl: return v.span
    }
    panic("Not an decl")
}

parser_panic_expr_token :: proc(parent: Expr, token: Token, error: string, level: int = 1) {
    p_span := get_expr_span(parent)
    c_span := token.span
    parser_panic_pos(c_span, error, level)
    fmt.println(expr_to_string(parent))
    for i in 0..<c_span.start.col - p_span.start.col {
        fmt.print(" ")
    }
    for i in 0..<c_span.end.col - c_span.start.col {
        fmt.print("^")
    }
    fmt.print("\n")
}


parser_panic_expr_parent :: proc(parent: Expr, expr: Expr, error: string, level: int = 1) {
    c_span := get_expr_span(expr)
    p_span := get_expr_span(parent)
    parser_panic_pos(c_span, error, level)
    fmt.println(expr_to_string(parent))
    for i in 0..<c_span.start.col - p_span.start.col {
        fmt.print(" ")
    }
    for i in 0..<c_span.end.col - c_span.start.col {
        fmt.print("^")
    }
    fmt.print("\n")
}


parser_panic_expr :: proc(expr: Expr, error: string, level: int = 1) {
    span := get_expr_span(expr)
    parser_panic_pos(span, error, level)
    fmt.println(expr_to_string(expr))
    for i in 0..<len(expr_to_string(expr)) {
        fmt.print("^")
    }
    fmt.println("")
}

parser_panic_decl_parent :: proc(parent: Decl, expr: Decl, error: string, level: int = 1) {
    c_span := decl_get_span(expr)
    p_span := decl_get_span(parent)
    parser_panic_pos(c_span, error, level)
    fmt.println(decl_to_string(parent))
    for i in 0..<c_span.start.col - p_span.start.col {
        fmt.print(" ")
    }
    for i in 0..<c_span.end.col - c_span.start.col {
        fmt.print("^")
    }
    fmt.print("\n")

}


parser_panic_decl :: proc(decl: Decl, error: string, level: int = 1) {
    span := decl_get_span(decl)
    parser_panic_pos(span, error, level)
    fmt.println(decl_to_string(decl))
    for i in 0..<len(decl_to_string(decl)) {
        fmt.print("^")
    }
    fmt.println("")
}


parser_panic_token :: proc(token: Token, error: string, level: int = 1) {
    parser_panic_pos(token.span, error, level)
    fmt.println(token.kind)
}

parser_next :: proc(p: ^Parser, amnt: int = 1) -> (Token, bool) #optional_ok {
    if p.pos+amnt >= len(p.tokens) do return Token({}), false
    return p.tokens[p.pos+amnt], true
}

parser_get :: proc(p: ^Parser, kinds: ..Token_Kind) -> (Token, bool) {
    for kind in kinds {
        if parser_peek(p).kind == kind {
            return parser_advance(p), true
        }
    }
    return {}, false
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
    strings.builder_destroy(&s_kinds);

    return parser_advance(p)
}

// ==== TYPE ======
// get_type :: proc {
//     get_type_parser,
//     get_type_token,
// }

// get_type_parser :: proc (p: ^Parser) -> (Type, bool) {
//     if t,ok := get_type_token(parser_peek(p).kind); ok {
//         return t, ok
//     }
//     else if parser_peek(p).kind == .STAR && parser_next(p).kind == .STAR {
//         parser_advance(p);
//         to := new(Type)
//         to^,_ = get_type_parser(p);
//         type := Pointer({to=to})
//         return type, true
//     }
//     else if parser_peek(p).kind == .STAR && is_type_token(parser_next(p).kind) {
//         // we are pointer
//         if t,ok := get_type_token(parser_next(p).kind); ok {
//             to := new(Type)
//             to^ = t
//             type := Pointer({to=to})
//             return type, true
//         }
//     }

//     return {}, false
// }

// parse_type :: proc (p: ^Parser) -> (Type, bool) {
//     token := parser_advance(p)
//     logln("++++====== token =====")
//     logln(token.lexeme)
    
//     if t,ok := get_type_token(token.kind); ok {
//         return t, ok
//     }else if is_struct(p, token) {
//         struc, ok := get_struct(p, token.lexeme)
//         if ok do return struc, true
//         else  do panic("TODO")
//     }
//     else if token.kind == .STAR {
//         // we are pointer
//         if t, ok := parse_type(p); ok {
//             to := new(Type)
//             to^ = t
//             return Pointer({to=to}), true
//         }
//     } else if token.kind == .LB {
//         // FIXME use this value inside the type
//         num := parser_expect(p, .NUMBER)
//         length,ok := strconv.parse_int(num.lexeme)
//         if !ok do panic("TODO HERE")
        
//         parser_expect(p, .RB)
//         // we are array
//         if t, ok := parse_type(p); ok {
//             of := new(Type)
//             of^ = t
//             return Array({of=of, length = u64(length)}), true
//         }
//     }

//     return {}, false
// }


// get_type_token :: proc (token: Token_Kind) -> (Type, bool) #optional_ok {
//      #partial switch token {
//          case .VOID: return Basic(.VOID), true
//          case .INT: return Basic(.INT), true
//          case .BYTE: return Basic(.BYTE), true
//          case .BOOL: return Basic(.BOOL), true
//          case .STRING: return Basic(.STRING), true
//          case .FLOAT:  return Basic(.FLOAT), true
//          case .DOUBLE: return Basic(.DOUBLE), true
//      }
//     return {}, false
// }

// is_type :: proc {
//     is_type_token,
//     is_type_parser
// }

// is_type_token :: proc (kind: Token_Kind) -> bool {
//     _, found := get_type_token(kind)
//     return found
// }

parser_is :: proc(p: ^Parser, kind: Token_Kind) -> bool{
    if parser_peek(p).kind == kind {
        parser_advance(p)
        return true
    }
    return false
}

// is_type_parser :: proc (p: ^Parser) -> bool {
//     pos := p.pos
//     defer p.pos = pos

//     if is_type_token(parser_peek(p).kind) do return true
//     else if is_struct(p, parser_peek(p)) do return true
//     else if parser_is(p, .STAR) && is_type(p) do return true
//     else if parser_is(p, .LB) && parser_is(p, .NUMBER) && parser_is(p, .RB) && is_type(p) {
//         return true
//     }

//     return false
// }

// ==== PARSING ====

parse_call_args :: proc(p: ^Parser) -> [dynamic]^Expr {
    logln("starting call args")
    args := make([dynamic]^Expr)
    parser_expect(p, .LPAR)
    first := true
    logln(parser_peek(p).kind)
    for parser_peek(p).kind != .RPAR {
        if !first do parser_expect(p, .COMMA)
        else      do first = false
        logln("parsing next arg")
        expr := parse_expression(p)
        logln("ARG:",expr_to_string(expr^))
        logln(parser_peek(p).kind)
        append(&args, expr)
    }
    parser_expect(p, .RPAR);
    return args
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


new_expr_binary :: proc(left, right: ^Expr, op: Token) -> ^Expr {
    expr := new(Expr)
    expr^ = Expr_Binary({
        span=Source_Span{
            start = get_expr_span(left^).start,
            end = get_expr_span(right^).end
        },
        left=left,
        right=right,
        op = op.kind
    })
    return expr
}

new_expr_unary :: proc(operand: ^Expr, operator: Token) -> ^Expr {
    expr := new(Expr)
    expr^ = Expr_Unary({
        span=Source_Span{
            start = get_expr_span(operand^).start,
            end = operator.span.end
        },
        operand=operand,
        operator = operator.kind
    })
    return expr
}

new_expr_call :: proc(name: ^Expr, args: [dynamic]^Expr, span: Source_Span) -> ^Expr {
    expr := new(Expr)
    expr^ = Expr_Call({
        span = span,
        name=name,
        args = args
    })
    return expr
}

new_expr_subscript :: proc(left: ^Expr, index: ^Expr) -> ^Expr {
    expr := new(Expr)
    expr^ = Expr_Subscript({
        span=Source_Span{
            start = get_expr_span(left^).start,
            end = get_expr_span(index^).end
        },
        left = left,
        index=index,
    })
    return expr
}

// get_token_type :: proc(token: Token_Kind) -> (Type, bool) {
//     #partial switch token {
//         case .NUMBER: return Basic(.INT), true
//         case .NUMBER_DOUBLE: return Basic(.DOUBLE), true
//         case .NUMBER_FLOAT: return Basic(.FLOAT), true
//         case .NUMBER_BOOL: return Basic(.BOOL), true
//     }
//     return {}, false
// }

parse_primary :: proc(p: ^Parser) -> ^Expr {
    if token, found := parser_get(p, .NUMBER, .NUMBER_BOOL, .NUMBER_FLOAT, .NUMBER_DOUBLE); found {
        type, ok := parse_type_token(token)
        expr := new(Expr)
        expr^ = Expr_Number({
            span=token.span,
            value=token.lexeme,
            type=type
        })
        return expr
    }
    else if token, found := parser_get(p, .STRING_LITERAL); found {
        expr := new(Expr)
        expr^ = Expr_String({
            span=token.span,
            value=token.lexeme,
        })
        return expr
    }
    else if token, found := parser_get(p, .IDENTIFER); found {
        expr := new(Expr)
        expr^ = Expr_Identifier({
            span=token.span,
            value=token.lexeme,
        })
        return expr
    }
    else if token, found := parser_get(p, .LPAR); found {
        expr := parse_expression(p);
        parser_expect(p, .RPAR)
        return expr
    }
    logln("PEEK is", parser_peek(p).kind)
    panic("TODO")
}


parse_postfix :: proc(p: ^Parser) -> ^Expr {
    left := parse_primary(p);
    for {
        if operator, found := parser_get(p, .UP, .AMPER); found { // DEREFERANCE
            left = new_expr_unary(left, operator)
        }
        else if operator, found := parser_get(p, .PUNCT); found { // Memeber access
            member := parser_expect(p, .IDENTIFER)

            expr := new(Expr)
            expr^ = Expr_MemberAccess{
                obj=left,
                member=member.lexeme,
                span=Source_Span{
                    start = get_expr_span(left^).start,
                    end = member.span.end
                }
            }
            left = expr

            logln("========================")
            logln(expr_to_string(left^))
            logln("========================")
        }
        else if operator, found := parser_get(p, .LPAR); found { // FUNCTION CALL
            p.pos -= 1; // parse_call_args expect peek to be LPAR so we go back once
            args := parse_call_args(p)
            span := Source_Span{
                start = get_expr_span(left^).start,
                end = get_expr_span(left^).end
            }
            left = new_expr_call(left, args, span)
            logln("AFTER CALL", parser_peek(p).kind)
            //parser_expect(p, .RPAR)
        }
        else if operator, found := parser_get(p, .LB); found { // subscript
            index := parse_expression(p);
            left = new_expr_subscript(left, index)
            parser_expect(p, .RB)
        }
        else do break
    }
    return left;
}

parse_term :: proc(p: ^Parser) -> ^Expr {
    left := parse_postfix(p); 
    for {
        operator, found := parser_get(p, .STAR, .DIVIDE)
        if !found {
            break
        }
        right := parse_postfix(p);
        left = new_expr_binary(left, right, operator)
    }

    return left
}



parse_additive :: proc (p: ^Parser) -> ^Expr {
    left := parse_term(p); 
    for {
        operator, found := parser_get(p, .PLUS, .MINUS)
        if !found {
            break
        }
        right := parse_term(p);
        left = new_expr_binary(left, right, operator)
    }

    return left
}

parse_condition :: proc(p: ^Parser) -> ^Expr {
    left := parse_additive(p);
    if operator, is := parser_get(p, .LESS, .GREATER, .EQ, .LEQ, .GEQ); is {
        right := parse_additive(p);
        left = new_expr_binary(left, right, operator)
    }
    return left
}

parse_and :: proc (p: ^Parser) -> ^Expr {
    left := parse_condition(p)
    for {
        operator, found := parser_get(p, .AND)
        if !found {
            break
        }

        right := parse_condition(p)
        left = new_expr_binary(left, right, operator)
    }
    return left
}


parse_or :: proc (p: ^Parser) -> ^Expr {
    left := parse_and(p)
    for {
        operator, found := parser_get(p, .OR)
        if !found {
            break
        }

        right := parse_and(p)
        left = new_expr_binary(left, right, operator)
    }
    return left
}

parse_assignment :: proc (p: ^Parser) -> ^Expr {
    left := parse_or(p)

    if operator, found := parser_get(p, .EQUAL); found {
        right := parse_assignment(p)
        return new_expr_binary(left, right, operator)
    }

    return left
}



parse_expression :: proc (p: ^Parser) -> ^Expr {
    left := parse_assignment(p)
    parser_skip(p, .SEMICOLON);
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

find_var :: proc(p: ^Parser, ident: Expr_Identifier) {

}

get_expr_type :: proc(expr: Expr) -> Type {
    #partial switch v in expr {
        case Expr_Array: panic("TODO")
        case Expr_Subscript:
        return v.type
        case Expr_Binary:
        #partial switch v.op {
            case .EQ:      return Basic(.BOOL)
            case .LEQ:     return Basic(.BOOL)
            case .GEQ:     return Basic(.BOOL)
            case .LESS:    return Basic(.BOOL)
            case .GREATER: return Basic(.BOOL)
            case .AND:     return Basic(.BOOL)
            case .OR:      return Basic(.BOOL)
            case: return get_expr_type(v.left^)
        }
        case Expr_Unary:
        return v.type
        case Expr_Number: return v.type
        case Expr_Identifier: return v.type
        case Expr_String:
        // TODO should be char
        return Pointer({})
        case Expr_Call: return v.type
        case Expr_MemberAccess:
        return v.type
   
    }
    panic("TODO")
}

is_struct ::  proc(p: ^Parser, id: Token) -> bool {
    for struc in p.package_.structs {
        fmt.println("is", struc.name, id.lexeme)
        if struc.name == id.lexeme do return true
    }
    return false
}
get_struct ::  proc(p: ^Parser, id: string) -> (Struct_Decl, bool) {
    for struc in p.package_.structs {
        if struc.name == id do return struc, true
    }
    return {}, false
}


is_decl :: proc(p: ^Parser) -> bool {
//    if is_type(parser_peek(p).kind) do return true
    if parser_next(p).kind         == .COLON do return true
    if parser_next(p, amnt=2).kind == .COLON do return true
    if parser_next(p).kind         == .COLON do return true
    if parser_peek(p).kind         == .FUNC do return true
    if parser_peek(p).kind         == .STAR do return true
    if parser_peek(p).kind         == .STRUCT do return true
    if parser_peek(p).kind         == .LB   do return true
    return false
}


parse_block :: proc(p: ^Parser, return_type: Type = .VOID) -> ^Block { 
    logln("parsing block")
    logln("LOOKING FOR START")
    parser_expect(p, .START)
    block := new(Block)
    p.current_block = block

    logln("FOUND START")
    for parser_peek(p).kind != .END {
        bef := parser_peek(p)

        if is_decl(p) {
            logln("IT IS DECL")
            append(&block.items, parse_decl(p))
        }
        else {
            stmt := parse_stmt(p)
            append(&block.items, stmt)
        }
        if bef == parser_peek(p) do parser_advance(p);
        logln("next stmt in block is", parser_peek(p).kind)
    }
    parser_expect(p, .END) // We consume end
    logln("block done", parser_peek(p).kind)
    return block
}

parse_if :: proc(p: ^Parser) -> ^If_Stmt {
    logln("===READ-IF-CONDITION===")
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

parse_return :: proc(p: ^Parser) -> Return_Stmt {
    ret := Return_Stmt({})
    ret.value = parse_expression(p)
    return ret
}

parse_type_token :: proc(token: Token) -> (Type, bool) {
    #partial switch token.kind {
        case .INT:           return Basic(.INT), true
        case .BYTE:          return Basic(.BYTE), true
        case .BOOL:          return Basic(.BOOL), true
        case .STRING:        return Basic(.STRING), true
        case .FLOAT:         return Basic(.FLOAT), true
        case .DOUBLE:        return Basic(.DOUBLE), true
        case .VOID:          return Basic(.VOID), true
        case .NUMBER:        return Basic(.INT), true
        case .NUMBER_FLOAT:  return Basic(.FLOAT), true
        case .NUMBER_DOUBLE: return Basic(.DOUBLE), true
        case .NUMBER_BOOL:   return Basic(.BOOL), true

    }
    return {}, false
}

parse_type_name :: proc(p: ^Parser) -> (Type, bool) {
    tn := strings.builder_make()
    defer strings.builder_destroy(&tn)
    
    name := parser_advance(p)
    if name.kind != .IDENTIFER {
        p.pos -= 1;
        return {}, false
    }

    strings.write_string(&tn, name.lexeme)
    for parser_is(p, .PUNCT) {
        strings.write_string(&tn, ".")
        strings.write_string(&tn, parser_expect(p, .IDENTIFER).lexeme)
    }
    return NamedType({value=fmt.tprintf("%s", strings.to_string(tn))}), true
}

parse_type :: proc(p: ^Parser) -> (Type, bool) {
    if parser_is(p, .STAR) {

        to_, ok := parse_type(p)
        if !ok {
            return {}, false
        }
        to := new(Type)
        to^ = to_

        return Pointer{to=to}, true
    }

    if t, ok := parse_type_token(parser_peek(p)); ok {
        parser_advance(p)
        return t, true
    }

    // named type
    expr, ok := parse_type_name(p)
    if ok {
        return expr, true
    }
    
    return {}, false
}

parse_func_decl :: proc(p: ^Parser) -> Function_Decl {
    decl := Function_Decl({})
    start := parser_skip(p, .FUNC).span
    logln("PEEK:",parser_peek(p))
    token := parser_expect(p, .IDENTIFER)
    decl.name = token.lexeme

    decl.args = make([dynamic]Variable_Decl)
    parser_skip(p, .LPAR,depth=1)
    for parser_peek(p).kind != .RPAR {
        var := parse_variable_decl(p)
        parser_skip(p, .COMMA, depth=1)
        append(&decl.args, var)
//     var := Variable_Decl({type=t})
        //     parser_skip(p, .STAR)
        //     parser_advance(p)
        //     var.name = parser_expect(p, .IDENTIFER).lexeme
        //     parser_skip(p, .COMMA, depth=1)
        //     append(&decl.args, var)
        // } else do panic("Could not determen type")
        //        }else do parser_panic(parser_peek(p), "Could not determen type")
        
    }

    for arg in decl.args do logln(arg)
    parser_skip(p, .RPAR,depth=1)

    if parser_is(p, .COLON) {
        type, ok := parse_type(p);
        if !ok do panic("EXPRESSION CANT BE TYPE")
        logln(type)
        decl.type = type
    }
    else {
        decl.type = Basic(.VOID);
        parser_panic(start, fmt.tprintf("warning: '%s' no type set" ,decl.name), 0)
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

parse_struct :: proc(p: ^Parser) -> Struct_Decl {
    decl := Struct_Decl({})
    parser_expect(p, .STRUCT)
    decl.name = parser_expect(p, .IDENTIFER).lexeme

    parser_expect(p, .START)

    for parser_peek(p).kind != .END {
        var := parse_variable_decl(p);
        append(&decl.members, var)
        
        print_decl(var)
    }
    
    print_decl(decl)

    return decl
}


parse_initlizer :: proc(p: ^Parser) -> (^Expr, bool) {
    token := parser_advance(p)
    // array initlizer
    if token.kind == .START {
        expr := new(Expr)
        expr_a := Expr_Array({})
        for parser_peek(p).kind != .END {
            val := parse_expression(p)
            parser_skip(p, .COMMA);
            append(&expr_a.values, val)
        }
        parser_expect(p, .END)
        parser_skip(p, .SEMICOLON)
        expr_a.span = Source_Span{
            start = token.span.start,
            end = get_expr_span(expr_a.values[len(expr_a.values)-1]^).end
        }
        expr^ = expr_a
        return expr, true
    } else {
        p.pos -= 1
        expr := parse_expression(p);
        return expr, true
    }
    return {}, false
}

parse_variable_decl :: proc(p: ^Parser) -> Variable_Decl {
    decl := Variable_Decl({})
    // this makes let variable declerations usable
    parser_skip(p, .LET, depth=1)

    name := parser_expect(p, .IDENTIFER)
    decl.name = name.lexeme

    logln("Var name is", decl.name)

    decl.span.start=name.span.start;
    
    parser_expect(p, .COLON)

    decl.span.end = parser_peek(p).span.end
    logln("Var looking for type", decl.name)

    type, ok := parse_type(p);
    if ok {
        decl.type = type
        logln("Var type is", decl.type)
    }


    if parser_is(p, .EQUAL) {
        if init, is := parse_initlizer(p); is {
            logln(name.lexeme, "=", expr_to_string(init^))
            decl.initlizer = init
            logln(get_expr_type(decl.initlizer^))
            if decl.type == nil do decl.type = get_expr_type(decl.initlizer^)

        }
        else {
            panic("HERE")
        }
    }

    return decl
}

parse_decl :: proc(p: ^Parser) -> Decl {
    decl := Decl({})
    
    if parser_peek(p).kind == .FUNC {
        decl = parse_func(p)
    }
    else if parser_peek(p).kind == .STRUCT {
        decl = parse_struct(p)
    }
    else {
        decl = parse_variable_decl(p)
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

parse_import :: proc(p: ^Parser) -> Import_Stmt {
    parser_expect(p, .IMPORT)
    value := parse_expression(p)
    return Import_Stmt{
        value = value
    }
}

parse_stmt :: proc(p: ^Parser) -> Stmt {
    token := parser_advance(p)
    stmt := Stmt({})
    logln("stmt next is ", parser_next(p).kind)

    #partial switch token.kind {
        case .WHILE:
        logln("parsing for stmt")
        stmt = parse_while(p);

        case .IF:
        logln("parsing if stmt")
        if_stmt := parse_if(p);
        stmt = if_stmt^;

        case .RETURN:
        logln("parsing return stmt")
        ret_stmt := parse_return(p)
        stmt = ret_stmt


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

parse_package :: proc(p: ^Parser) -> Package {

    package_ := Package({})
    p.package_ = &package_
    parser_expect(p, .PACKAGE)
    name := parse_expression(p)
    package_.package_name = expr_to_string(name^)

    logln("PACKGE NAME IS", package_.package_name)

    for parser_peek(p).kind != .EOF && parser_peek(p).kind != .INVALID  {
        bef := parser_peek(p)
        logln(bef)
        #partial switch parser_peek(p).kind {
            case .EXTERN:
            parser_advance(p)
            func := parse_func_decl(p)
            func.extern = true
            parser_skip(p, .SEMICOLON)
            append(&package_.functions, func)            

            case .STRUCT:
            struc := parse_struct(p)
            append(&package_.structs, struc)

            
            case .IMPORT:
            logln("parsing import stmt")
            import_stmt := parse_import(p)
            append(&package_.imports, import_stmt)
            
            case .FUNC:
            func := parse_func(p)
            logln("===FUNC===")
            logln(func.name, func.args[:])
            print_block(func.block^)
            append(&package_.functions, func)
        }
        parser_skip(p,.SEMICOLON)
        if bef == parser_peek(p) do parser_advance(p)
        logln("after prase", parser_peek(p))
    }
    return package_

}

print_indent :: proc(depth: int) {
    for _ in 0..<depth {
        log("  ")
    }
}

type_to_string :: proc(type: Type) -> string {
    switch v in type {
    case NamedType: return fmt.tprintf("'%s'", v.value)
    case Struct_Decl:
        return fmt.tprintf("'%s'", v.name)
    case Basic:
        return strings.to_lower(fmt.tprintf("%s", v))
    case Pointer:
        if v.to == nil do return fmt.tprintf("ptr")
        return fmt.tprintf("*{}", type_to_string(v.to^))
    case Array:
        if v.of == nil {
            return fmt.tprintf("[{}]", v.length)
        }
        return fmt.tprintf("[{}]{}", v.length, type_to_string(v.of^))
    }
    return "<unknown type>"
}

decl_to_string :: proc(decl_u: Decl) -> string {
    #partial switch decl in decl_u {
        case Function_Decl: return fmt.tprintf("func {}({}): {}", decl.name, "", decl.type);
        case Variable_Decl:
        if decl.initlizer == nil {
            return fmt.tprintf("{} {}", type_to_string(decl.type), decl.name)
        }
        return fmt.tprintf("{} {} = {}", type_to_string(decl.type), decl.name, expr_to_string(decl.initlizer^))
        case Struct_Decl:
        return fmt.tprintf("struct {} {}", decl.name, "{}")
    }

    return "<unknown expr>"
}


operator_to_string :: proc(token: Token_Kind) -> string {
    #partial switch token {
    case .EQUAL:   return "="
    case .LESS:    return "<"
    case .GREATER: return ">"
    case .LEQ:     return "<="
    case .GEQ:     return ">="
    case .AND:     return "&&"
    case .OR:      return "||"
    case .UP:      return "^"
    case .AMPER:   return "&"
    case .PLUS:    return "+"
    case .MINUS:   return "-"
    case .STAR:    return "*"
    case .DIVIDE:  return "/"

    }
    return "<unknown operator>"
}


expr_to_string :: proc(expr_u: Expr) -> string {
    
    #partial switch expr in expr_u {
        case Expr_Binary:
        left := expr_to_string(expr.left^)
        right := expr_to_string(expr.right^)
        return fmt.tprintf("%s %v %s", left, operator_to_string(expr.op), right)

        case Expr_Subscript:
        left := expr_to_string(expr.left^)
        index := expr_to_string(expr.index^)
        return fmt.tprintf("%s[%s]", left, index)

        case Expr_Number:
        return fmt.tprintf("%s", expr.value)

        case Expr_String:
        return fmt.tprintf("%s", expr.value)

        case Expr_Unary:
        return fmt.tprintf("{}{}", expr_to_string(expr.operand^), operator_to_string(expr.operator))

        case Expr_MemberAccess:
        return fmt.tprintf("{}.{}", expr_to_string(expr.obj^), expr.member)
        case Expr_Identifier:
        return expr.value

        case Expr_Call:
        result := strings.builder_make()
        strings.write_string(&result, fmt.tprintf("{}(", expr.name != nil ? expr_to_string(expr.name^) : ""))

        for i in 0..<len(expr.args) {
            arg := expr.args[i]
            if i > 0 && i < len(expr.args) do strings.write_string(&result, ", ")
            strings.write_string(&result, expr_to_string(arg^))
        } 
        strings.write_string(&result, ")")
        val := strings.to_string(result)

        strings.builder_destroy(&result)

        return val
    }

    return "<unknown expr>"
}

print_expr :: proc(expr_u: Expr, depth: int = 0) {
    print_indent(depth)
    logln("<", type_to_string(get_expr_type(expr_u)), ">")
    print_indent(depth)
    switch expr in expr_u {
    case Expr_Array: panic("TODO")
    case Expr_MemberAccess:
        logln("MemberAccess ");
        if expr.obj == nil do panic("asd")
        print_expr(expr.obj^,depth=depth+1)
        print_indent(depth+1)
        log(expr.member,"\n")

    case Expr_Binary:
        logln("Binary ", expr.op)
        print_expr(expr.left^, depth + 1)
        print_expr(expr.right^, depth + 1)

    case Expr_Subscript:
        logln("Subscript")
        print_expr(expr.left^, depth + 1)
        print_expr(expr.index^, depth + 1)

    case Expr_Number:
        logln("Number: ", expr.value)

    case Expr_String:
        logln("String: \"", expr.value, "\"")

    case Expr_Identifier:
        logln("Identifier: ", expr.value)
    case Expr_Unary:
        logln("Unary: ", expr_to_string(expr.operand^), " ", expr.operator)
    case Expr_Call:
        fmt.println(expr.name)
        logln("Call: ", expr.name != nil ? expr_to_string(expr.name^) : "")
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
        logln("type =", type_to_string(v.type))
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
        case Struct_Decl:
        print_indent(depth)
        logln("Struct: ", decl.name)
        for member in decl.members {
            print_decl(member, depth+1)
        }
        
        case Function_Decl:
        print_indent(depth)
        log("Function: ", decl.name, "(")
        for arg in decl.args do log(arg.name, ":", arg.type, ",")
        logln("):",decl.type)

        if decl.block != nil {
            print_block(decl.block^, depth + 1)
        }

        case Variable_Decl:
        print_indent(depth)
        logln("Variable: ", decl.name, " : ", type_to_string(decl.type))

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

print_package :: proc(package_: Package) {
    logln("Program", package_.package_name)
    for struc in package_.structs {
        print_decl(struc, 1)
    }
    for func in package_.functions {
        print_decl(func, 1)
    }
}

// FREE MEMORY
// NOT USED BECAUSE WE ARE USING AN AREANA

delete_type :: proc(type_u: ^Type) {
    switch type in type_u {
    case NamedType: panic("TODO")
    case Basic:
    case Pointer:
        delete_type(type.to)
        free(type.to)
    case Array:
        delete_type(type.of)
        free(type.of)
    case Struct_Decl:
        panic("TODO")
        
    }
}

delete_expression :: proc(expr_u: ^Expr) {
    switch &expr in expr_u {
    case Expr_MemberAccess:
        delete_expression(expr.obj)
    case Expr_Array:
        for v in expr.values {
            delete_expression(v)
        }
        delete(expr.values)
    case Expr_Subscript:
        delete_expression(cast(^Expr)expr.left);
        delete_expression(expr.index)
        delete_type(&expr.type)
    case Expr_Number:
        delete_type(&expr.type);
    case Expr_String:
    case Expr_Identifier:
        delete_type(&expr.type)
    case Expr_Binary:
        delete_expression(expr.left)
        delete_expression(expr.right)
    case Expr_Call:
        for a in expr.args {
            delete_expression(a)
        }
        delete(expr.args)
        delete_type(&expr.type)

    case Expr_Unary:
        delete_expression(expr.operand)
    }
    free(expr_u)
}


delete_block :: proc(block: ^Block) {
    for &item_u in block.items {
        switch &item in item_u {
        case Decl:
            #partial switch &decl in item {
                case Function_Decl:
                if decl.block != nil do delete_block(decl.block)
                delete(decl.args)
                case Variable_Decl:
                delete_type(&decl.type)
                delete_expression(decl.initlizer)
            }
        case Stmt:
            switch &stmt in item {
            case Expr: delete_expression(&stmt)
            case Return_Stmt:
                delete_expression(stmt.value)
            case If_Stmt: panic("TODO")
            case While_Stmt: panic("TODO")
            case Block: delete_block(&stmt)
            }
            
        }
    }
    free(block)
}

delete_function :: proc(func: ^Function_Decl) {
    if func.block != nil do delete_block(func.block)
    delete_type(&func.type)
    for &a in func.args {
        delete_type(&a.type)
        if a.initlizer != nil do delete_expression(a.initlizer)
    }
    delete(func.args)
}

delete_program :: proc(program: ^Package) {
    for &func in program.functions {
        delete_function(&func)
    }
    delete(program.extern)
    delete(program.functions)
}
