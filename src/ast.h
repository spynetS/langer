#ifndef AST_H
#define AST_H

#include "lexer.h"

#include <stdint.h>

typedef struct Ast Ast;

typedef enum {
    VIS_PRIVATE,
    VIS_PUBLIC,
} Visibility;

typedef enum {
  // Declarations
  AST_INVALID,
  
  AST_PACKAGE,
  AST_IMPORT,


  AST_FUNC_DECL,
  AST_STRUCT_DECL,
  AST_ENUM_DECL,
  AST_UNION_DECL,

  AST_VAR_DECL,

  //Statments
  AST_BLOCK,
  AST_RETURN,
  AST_IF,
  AST_WHILE,
  AST_FOR,
  AST_EXPR_STMT,

  //Expressions
  AST_INTEGER_LITERAL,
  AST_FLOAT_LITERAL,
  AST_STRING_LITERAL,
  AST_CHAR_LITERAL,
  AST_IDENTIFER,
  AST_BOOL_LITERAL,

  AST_BINARY,
  AST_UNARY,
  AST_ASSIGN,
  AST_DECL,
  AST_CALL,
  AST_MEMBER,
  AST_INDEX,
  AST_CAST,
  AST_COMPOUND_LITERAL,
  
  // Types
  AST_TYPE_VOID,
  AST_TYPE_BOOL,
  AST_TYPE_BYTE,
  AST_TYPE_I16,
  AST_TYPE_I32,
  AST_TYPE_I64,
  AST_TYPE_F32,
  AST_TYPE_F64,

  AST_TYPE_NAME,
  AST_TYPE_POINTER,
  AST_TYPE_ARRAY,



} AstKind;

typedef struct {
  char *data;
  size_t length;
} String;

typedef struct {
  int value;
} IntExpr;

typedef struct {
  float value;
} FloatExpr;

typedef struct {
  double value;
} DoubleExpr;

typedef struct {
  bool value;
} BoolExpr;

typedef struct {
  char value;
} ByteExpr;

typedef struct {
  uint32_t value;
} CharExpr;

typedef struct {
  Ast *expression;
  Ast *cast_type;
} CastExpr;


typedef struct {
  String value;
} StringExpr;

typedef struct {
  const char* value;
} IdentiferExpr;

typedef struct {
  Ast *left;
  Ast *right;
  TokenKind operator;
} BinaryExpr;

typedef struct {
  Ast *left;
  Ast *value;
} AssignExpr;


typedef struct {
  Ast *value;
} ReturnStmt;

typedef struct {
  const char* value;
} PackageStmt;

typedef struct {
  Ast* to;
} PointerType;

typedef struct {
  const char* name;
} NamedType;

typedef struct {
  Ast* left;
  Ast** parameters;
} CallExpr;

typedef struct {
  Ast* operand;
  TokenKind operator;
} UnaryExpr;

typedef struct {
  Ast *left;
  Ast *index;
} IndexExpr;

typedef struct {
  Ast *left;
  const char *member;
} MemberAccessExpr;

typedef struct {
  Ast *left;
  Ast *initlizer;
  Ast *type;
  Visibility visibility;
} VariableDecl;


typedef struct {
  const char* name;
  Ast** members;
  Visibility visibility;
} StructDecl;


typedef struct {
  const char* name;
  Ast** parameters;
  Ast* return_type;
  Ast* body;
  bool is_extern; // If it is not defined in langer
  Visibility visibility;
} FunctionDecl;

typedef struct {
  Ast** stmts;
} BlockStmt;

typedef struct {
  Ast* condition;
  Ast* body;
  Ast* else_if_stmt;
  Ast* else_body;
} IfStmt;

typedef struct {
  PackageStmt package;
  VariableDecl* variables;
  FunctionDecl* functions;
  StructDecl* structs;
} Package;



typedef struct Ast {
  AstKind kind;
  union {
    BoolExpr bool_expr;
    ByteExpr byte_expr;
    IntExpr int_expr;
    FloatExpr float_expr;
    DoubleExpr double_expr;
    CharExpr char_expr;
    StringExpr string_expr;
    IdentiferExpr identifer_expr;

    AssignExpr assign_expr;
    BinaryExpr binary_expr;
    CallExpr call_expr;
    MemberAccessExpr member_expr;
    UnaryExpr unary_expr;
    IndexExpr index_expr;
    CastExpr cast_expr;

    ReturnStmt return_stmt;
    PackageStmt package_stmt;
    BlockStmt block_stmt;
    IfStmt if_stmt;

    VariableDecl variable_decl;
    FunctionDecl function_decl;
    StructDecl struct_decl;

    PointerType pointer_type;
    NamedType named_type;
    

  } value;
} Ast;



void free_ast(Ast *ast);
void print_ast(Ast *ast, int depth);
void print_func_decl(FunctionDecl decl, int depth);

#endif
