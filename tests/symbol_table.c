#include "minunit.h"
#include "../src/lexer.h"
#include "../src/utils.h"
#include "../src/parser.h"
#include "../src/symbol_table.h"

#include <string.h>
#include <stdio.h>
#include <stdbool.h>

MU_TEST(test_symbol1) {

  Lexer lexer = {0};
  size_t size = 0;
  lexer.bytes = read_file("./tests/program.l", &size);
  lexer.bytes_length = size;

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);


  Parser p = {0};
  p.tokens = tokens;

  Package *package = parse_package(&p);

  SymbolTable root = {0};
  symbol_table_package(&root, package);

  TypeResolver resolver = {0};
  resolver.scope = &root;
  symbol_table_resolve_types(&resolver, &root);
  print_symbol_table(&root, 0);

  mu_check(1);
}

MU_TEST_SUITE(test_suite_symbol_table) {
  MU_RUN_TEST(test_symbol1);
}
