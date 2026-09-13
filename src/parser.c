#include "parser.h"
#include "utils.h"
#include <stdio.h>
#include <stdlib.h>

Token parser_advance(Parser *p) {
  Token t = p->tokens[p->pos];
  p->pos += 1;
  return t;
}
Token parser_peek(Parser *p) {
  Token t = p->tokens[p->pos];
  return t;
}


Expr* parser_create_expr() {
  
}

Token parser_skip(Parser* p, TokenKind kind) {
  return parser_peek(p);
}

Expr *parse_assignment(Parser* p) {
  Token t = parser_advance(p);
  Expr *a = malloc(sizeof(Expr));
  a->kind = EXPR_IDENTIFER;
  a->value.identifer_expr = (IdentiferExpr){t.lexeme};
  return a;
}

Expr *parse_expression(Parser *p) {
  Expr *left = parse_assignment(p);
  parser_skip(p, TOKEN_SEMICOLON);
  return left;
}
