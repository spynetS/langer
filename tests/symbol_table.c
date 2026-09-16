#include "minunit.h"
#include "../src/lexer.h"
#include "../src/parser.h"
#include "../src/symbol_table.h"

#include <string.h>
#include <stdio.h>
#include <stdbool.h>

MU_TEST(test_symbol1) {

  char *val = "func main(): int";

  Lexer lexer = {0};
  lexer.bytes = (char*)val;
  lexer.bytes_length = strlen(lexer.bytes);

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);


  Parser p = {0};
  p.tokens = tokens;

  Ast* ast = parse_function(&p);
  print_ast(ast, 0);

  SymbolTable root;
  Symbol *sym = symbol_define(&root, ast, ast->value.function_decl.name);
  print_symbol(sym);

  mu_check(1);
}

MU_TEST_SUITE(test_suite_symbol_table) {
  MU_RUN_TEST(test_symbol1);
}
