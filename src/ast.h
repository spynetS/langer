#ifndef AST_H
#define AST_H

typedef enum {
  // Declarations
  PACKAGE,
  IMPORT,

  FUNC_DECL,
  STRUCT_DECL,
  ENUM_DECL,
  UNION_DECL,

  VAR_DECL,

  //Statments
  BLOCK,
  RETURN,
  IF,
  WHILE,
  FOR,
  EXPR_STMT,

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

typedef enum {
  EXPR_INTEGER_LITERAL,
  EXPR_FLOAT_LITERAL,
  EXPR_STRING_LITERAL,
  EXPR_CHAR_LITERAL,
  EXPR_IDENTIFER,
  EXPR_BOOL_LITERAL,

  EXPR_BINARY,
  EXPR_UNARY,
  EXPR_ASSIGN,
  EXPR_CALL,
  EXPR_MEMBER,
  EXPR_INDEX,
  EXPR_CAST,
  EXPR_COMPOUND_LITERAL,
} ExprKind;

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
  const char* value;
} IdentiferExpr;


typedef struct {
  ExprKind kind;
  union {
    BoolExpr bool_expr;
    ByteExpr byte_expr;
    IntExpr int_expr;
    FloatExpr float_expr;
    DoubleExpr double_expr;
    IdentiferExpr identifer_expr;
  } value;
} Expr;

typedef struct {
  AstKind kind;
  union {
    Expr expr;
  } value;
} Ast;






#endif
