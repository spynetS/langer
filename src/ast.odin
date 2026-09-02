package main;

import "core:fmt"

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
    path: [dynamic]string
}
Array :: struct {
    of: ^Type,
    length: u64
}

Pointer :: struct {
    to: ^Type
}

StructType :: struct {
    path: [dynamic]string,
    members: [dynamic]^Variable_Decl,
}

Type :: union {
    Basic,
    Array,
    Pointer,
    NamedType,
    StructType
}



Package :: struct {
    package_name: string,
    file: string,
    extern    : [dynamic]string,
    functions : [dynamic]^Function_Decl,
    structs   : [dynamic]^Struct_Decl,
    imports   : [dynamic]Import_Stmt,
}


Variable_Decl :: struct {
    span: Source_Span,
    name: string,
    initlizer: ^Expr,
    type: Type,
}

Function_Decl :: struct {
    span: Source_Span,
    name: string,
    type: Type,
    args: [dynamic]^Variable_Decl,
    block: ^Block,
    extern: bool
}

Struct_Decl :: struct {
    span: Source_Span,
    name: string,
    members: [dynamic]^Variable_Decl,
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
    items: [dynamic]^BlockItem,
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

Package_Decl :: struct {
    name: string
}

Decl :: union {
    Function_Decl,
    Variable_Decl,
    Struct_Decl,
    Package_Decl
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
    type: Type,
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
    right: ^Expr,
    type: Type,
    
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


/* Types */
decl_get_type :: proc(decl: Decl) -> Type {
    switch v in decl {
    case Variable_Decl: return v.type
    case Function_Decl: return v.type
    case Struct_Decl: panic("TODO")
    case Package_Decl: panic("ASD")
    }
    fmt.println(decl)
    panic("TODO")
}

decl_set_type :: proc(decl: ^Decl, type: Type) {
    switch &v in decl {
    case Variable_Decl: v.type = type
    case Function_Decl: v.type = type
    case Struct_Decl:  panic("SHOULDNT")
    case Package_Decl: panic("SHOULDNT")
        
    }
}
new_named_type :: proc(path: []string) -> NamedType {
    new_path := make([dynamic]string)
    for p in path do append(&new_path, p)
    return NamedType{path=new_path}
}
