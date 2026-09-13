#include "minunit.h"
#include "../src/parser.h"
#include "../src/lexer.h"
#include "../src/ast.h"

#include <string.h>
#include <stdio.h>


Token *get_tokens(const char *val) {
  Lexer lexer = {0};
  lexer.bytes = (char*)val;
  lexer.bytes_length = strlen(lexer.bytes);

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);
  return tokens;
}



MU_TEST(test_assign1) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := 67");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_ASSIGN);
  mu_check(e->value.assign_expr.initlizer->kind == AST_INTEGER_LITERAL);
  mu_check(e->value.assign_expr.initlizer->value.int_expr.value == 67);
}

MU_TEST(test_assign2) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := 67.69");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_ASSIGN);
  mu_check(e->value.assign_expr.initlizer->kind == AST_FLOAT_LITERAL);
  mu_check((int)e->value.assign_expr.initlizer->value.float_expr.value*100 == (int)67.69*100);
}


MU_TEST(test_assignidentifer) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := alfred2");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_ASSIGN);
  mu_check(e->value.assign_expr.initlizer->kind == AST_IDENTIFER);
  mu_check(strcmp(e->value.assign_expr.initlizer->value.identifer_expr.value, "alfred2") == 0);
}

MU_TEST(test_assignstring) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := \"Alfred\"");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_ASSIGN);
  mu_check(e->value.assign_expr.initlizer->kind == AST_STRING_LITERAL);
  mu_check(strcmp(e->value.assign_expr.initlizer->value.string_expr.value, "\"Alfred\"") == 0);
}

MU_TEST_SUITE(test_suite_parser) {
  MU_RUN_TEST(test_assign1);
  MU_RUN_TEST(test_assign2);
  MU_RUN_TEST(test_assignidentifer);
  MU_RUN_TEST(test_assignstring);
}
