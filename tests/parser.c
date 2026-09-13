#include "minunit.h"
#include "../src/parser.h"
#include "../src/lexer.h"
#include "../src/ast.h"

#include <string.h>
#include <stdio.h>




MU_TEST(test_expr1) {
  Parser p = {0};
  Lexer lexer = {0};
  lexer.bytes = "alfred := 10";
  lexer.bytes_length = strlen(lexer.bytes);

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);
  p.tokens = tokens;

  Expr* e = parse_expression(&p);
  printf("\n%s\n", e->value.identifer_expr.value);
}


MU_TEST_SUITE(test_suite_parser) {
  MU_RUN_TEST(test_expr1);
}
