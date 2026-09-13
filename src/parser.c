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

void print_ast(Ast *ast, int depth) {
  if (ast == NULL) return;
  for (int i = 0; i < depth; i ++) debug_log(" ");
  switch (ast->kind) {
  case AST_ASSIGN:
    debug_log("Assign\n");
    print_ast(ast->value.assign_expr.left, depth+1);
    //print_ast(ast->value.assign_expr.type, depth+1);
    print_ast(ast->value.assign_expr.initlizer, depth+1);
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


Token parser_skip(Parser* p, TokenKind kind) {
  return parser_peek(p);
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
  debug_log("TODO IMPLEMENT term\n");
  Ast *left = parse_postfix(p);
  return left;
}

Ast *parse_additive(Parser *p) {
  debug_log("TODO IMPLEMENT additive\n");
  Ast *left = parse_term(p);
  return left;
}

Ast *parse_condition(Parser *p) {
  debug_log("TODO IMPLEMENT condition\n");
  Ast *left = parse_additive(p);
  return left;
}

Ast *parse_and(Parser *p) {
  debug_log("TODO IMPLEMENT and\n");
  Ast *left = parse_condition(p);
  return left;
}


Ast *parse_or(Parser *p) {
  debug_log("TODO IMPLEMENT OR\n");
  Ast *left = parse_and(p);
  return left;
}

Ast *parse_assignment(Parser* p) {
  Ast* left = parse_or(p);
  if (parser_is(p, TOKEN_COLON) == true) {
    Ast *left_ = left;
    left = malloc(sizeof(Ast));
    left->kind = AST_ASSIGN;
    left->value.assign_expr = (AssignExpr) {
      left_,
    };
    free_ast(left_);

    if (parser_is(p, TOKEN_ASSIGN) == true) {
      debug_log("We should guess type of initlizer\n");

      Ast *initlizer = parse_expression(p);
      debug_log("after0\n");
      left->value.assign_expr.initlizer = initlizer;
      //panic("SHOULD PARSE INITLIZER");
    }
    else {
      Ast *type = parse_type(p);
      left->value.assign_expr.type = type;
    }
  }
  return left;
}

Ast *parse_expression(Parser *p) {
  debug_log("Parsing expresstion\n");
  Ast *left = parse_assignment(p);
  debug_log("After\n");
  /* parser_skip(p, TOKEN_SEMICOLON); */

  print_ast(left,0);

  return left;
}



void free_ast(Ast *ast) {

}
