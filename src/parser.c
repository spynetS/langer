#include "parser.h"
#include "stb_ds.h"
#include "ast.h"
#include "lexer.h"
#include "utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>


Token parser_advance(Parser *p) {
  assert(p->pos < arrlen(p->tokens));
  Token t = p->tokens[p->pos];
  p->pos += 1;
  return t;
}
Token parser_peek(Parser *p) {
  assert(p->pos < arrlen(p->tokens));
  Token t = p->tokens[p->pos];
  return t;
}
Token parser_next(Parser *p) {
  assert(p->pos+1 < arrlen(p->tokens));
  Token t = p->tokens[p->pos+1];
  return t;
}

void print_ast(Ast *ast, int depth) {
  if (ast == NULL) return;
  for (int i = 0; i < depth; i ++) debug_log(" ");
  switch (ast->kind) {
  case AST_DECL:
    debug_log("Variable Decl (%s)\n", ast->value.decl_expr.type != NULL ? token_kind_to_string(ast->value.decl_expr.type->kind): "unknown type");
    print_ast(ast->value.decl_expr.left, depth+1);
    //print_ast(ast->value.decl_expr.type, depth+1);
    print_ast(ast->value.decl_expr.initlizer, depth+1);
    break;
  case AST_ASSIGN:
    debug_log("Variable Assign\n");
    print_ast(ast->value.assign_expr.left, depth+1);
    print_ast(ast->value.assign_expr.value, depth+1);
    break;
  case AST_IDENTIFER:
    debug_log("Identifer (%s)\n", ast->value.identifer_expr.value);
    break;
  case AST_INTEGER_LITERAL:
    debug_log("Integer (%d)\n", ast->value.int_expr.value);
    break;
  case AST_FLOAT_LITERAL:
    debug_log("Float (%f)\n", ast->value.float_expr.value);
    break;
  case AST_BINARY:
    debug_log("Binary\n");
    print_ast(ast->value.binary_expr.left, depth+1);
    for (int i = 0; i < depth+1; i ++) debug_log(" ");
    print_token(ast->value.binary_expr.operator);
    print_ast(ast->value.binary_expr.right, depth+1);
  default:
    debug_log("\n");
    break;
  }

}

bool parser_is(Parser *p, TokenKind kind) {
  //print_token(parser_peek(p));
  if (parser_peek(p).kind == kind) {
    debug_log("parser is \n");
    parser_advance(p);
    return true;
  }
  return false;
}

Ast *parse_type(Parser *p) {
  Ast *ast = malloc(sizeof(Ast));

  Token next = parser_advance(p);
  print_token(next);
  switch (next.kind) {
  case TOKEN_BYTE:
    ast->kind = AST_TYPE_BYTE;
    break;
  case TOKEN_I16:
    ast->kind = AST_TYPE_I16;
    break;
  case TOKEN_I32:
    ast->kind = AST_TYPE_I32;
    break;
  case TOKEN_F32:
    ast->kind = AST_TYPE_F32;
    break;
  case TOKEN_F64:
    ast->kind = AST_TYPE_F64;
    break;
  default:
    log_span(next.span, "No type\n");
    break;
  }

  return ast;
}

Token parser_skip(Parser *p, TokenKind kind) {
  while (parser_peek(p).kind == kind) {
    parser_advance(p);
  }
  return parser_peek(p);
}


Ast *new_binary_expr(Ast* left, Ast* right, Token operator) {
  Ast *binary = malloc(sizeof(Ast));
  binary->kind = AST_BINARY;
  binary->value.binary_expr = (BinaryExpr){left, right, operator};
  return binary;
}

Ast *parse_primary(Parser *p) {
  Ast *ast = malloc(sizeof(Ast));
  Token token = parser_advance(p);
  debug_log("primary -- ");
  print_token(token);
  

  switch (token.kind) {
  case TOKEN_INTEGER_LITERAL:
    debug_log("Primary int\n");
    ast->kind = AST_INTEGER_LITERAL;
    ast->value.int_expr = (IntExpr){
      atoi(token.lexeme)
    };
    return ast;

  case TOKEN_FLOAT_LITERAL:
    debug_log("Primary float\n");
    ast->kind = AST_FLOAT_LITERAL;
    ast->value.float_expr = (FloatExpr){
      atof(token.lexeme)
    };
    return ast;
  case TOKEN_STRING_LITERAL:
    debug_log("Primary string literal %s\n", token.lexeme);
    ast->kind = AST_STRING_LITERAL;
    ast->value.string_expr = (StringExpr){
      token.lexeme
    };
    return ast;
  case TOKEN_IDENTIFER:
    debug_log("Primary identifer %s\n", token.lexeme);
    ast->kind = AST_IDENTIFER;
    ast->value.identifer_expr = (IdentiferExpr){
      token.lexeme
    };
    return ast;

  default:
    debug_log("Primary error\n");
    log_span(token.span, "Primary error\n");
    return NULL;
  }

  // return left;
  return NULL;
}

Ast *parse_postfix(Parser *p) {
  debug_log("TODO IMPLEMENT postfix\n");
  Ast *left = parse_primary(p);
  return left;
}

Ast *parse_term(Parser *p) {
    Ast *left = parse_postfix(p);

    while (1) {
        Token token = parser_peek(p);

        if (token.kind != TOKEN_STAR &&
            token.kind != TOKEN_SLASH) {
            break;
        }

        debug_log("Found operators star slash\n");
        parser_advance(p);

        Ast *right = parse_postfix(p);
        left = new_binary_expr(left, right, token);
    }

    return left;
}

Ast *parse_additive(Parser *p) {
    Ast *left = parse_term(p);

    while (1) {
        Token token = parser_peek(p);

        if (token.kind != TOKEN_PLUS &&
            token.kind != TOKEN_MINUS) {
            break;
        }

        debug_log("Found operators plus minus\n");
        parser_advance(p);

        Ast *right = parse_term(p);
        left = new_binary_expr(left, right, token);

    }

    return left;
}


Ast *parse_condition(Parser *p) {
  Ast *left = parse_additive(p);

  Token token = parser_peek(p);
  if (token.kind == TOKEN_LESS  || token.kind == TOKEN_GREATER ||
      token.kind == TOKEN_EQUAL || token.kind == TOKEN_LE      ||
      token.kind == TOKEN_GE    || token.kind == TOKEN_NOTEQUAL) {
    Ast* right = parse_expression(p);
    left = new_binary_expr(left, right, token);
  }

  return left;
}

Ast *parse_and(Parser *p) {
  Ast *left = parse_condition(p);

  while (1) {
    Token token = parser_peek(p);

    if (token.kind != TOKEN_AND) {
      break;
    }

    debug_log("Found or operator\n");
    parser_advance(p);

    Ast *right = parse_term(p);
    left = new_binary_expr(left, right, token);
  }

  return left;
}


Ast *parse_or(Parser *p) {
  Ast *left = parse_and(p);

  while (1) {
    Token token = parser_peek(p);

    if (token.kind != TOKEN_OR) {
      break;
    }

    debug_log("Found or operator\n");
    parser_advance(p);

    Ast *right = parse_term(p);
    left = new_binary_expr(left, right, token);
  }

  return left;
}

Ast *parse_variable_decl(Parser *p) {
  Ast *left_ = parse_or(p);
  Ast *left = malloc(sizeof(Ast));
  left->kind = AST_DECL;
  left->value.decl_expr = (DeclExpr) {0};
  left->value.decl_expr.left = left_;
  

  if (parser_advance(p).kind != TOKEN_COLON) {
    panic("AH");
  }
  // if next isnt equals we should try to parse a type
  if (parser_peek(p).kind != TOKEN_ASSIGN) {
    Ast *type = parse_type(p);
    left->value.decl_expr.type = type;
  }
  // if next is assign we should try to parse initlizer
  if (parser_is(p, TOKEN_ASSIGN) == true) {
    debug_log("We should guess type of initlizer\n");

    Ast *initlizer = parse_expression(p);
    debug_log("after0\n");
    left->value.decl_expr.initlizer = initlizer;
  }

  return left;
}

Ast *parse_assignment(Parser* p) {
  Ast* left = parse_or(p);
  if (parser_is(p, TOKEN_ASSIGN)) {
    Ast *left_ = left;
    left = malloc(sizeof(Ast));
    left->kind = AST_ASSIGN;
    left->value.assign_expr = (AssignExpr) {
      left_,
      parse_or(p)
    };
  }
  return left;
}

Ast *parse_expression(Parser *p) {
  debug_log("Parsing expresstion\n");
  Ast *left = parse_assignment(p);
  debug_log("After\n");
  parser_skip(p, TOKEN_SEMICOLON);

  print_ast(left,0);

  return left;
}

Ast *parse_stmt(Parser *p) {
  if (parser_peek(p).kind == TOKEN_IF) {
    panic("TODO if parsing");
  }
  else if (parser_peek(p).kind == TOKEN_FOR) {
    panic("TODO for parsing");
  }
  else if (parser_peek(p).kind == TOKEN_WHILE) {
    panic("TODO while parsing");
  }
  else if (parser_peek(p).kind == TOKEN_RETURN) {
    panic("TODO return parsing");
  }
  else if (parser_next(p).kind == TOKEN_COLON) {
    debug_log("parser decl\n");
    return parse_variable_decl(p);
  } else if (parser_peek(p).kind != TOKEN_EOF) {
    return parse_expression(p);
  }
  
  return 0;
}


void free_ast(Ast *ast) {

}
