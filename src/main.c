#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include "lexer.h"
#include "parser.h"
#include "llvm.h"
#define STB_DS_IMPLEMENTATION
#include "../include/stb_ds.h"
#include "utils.h"

// lexer
// parser
// resolver
// checker
// generator

void print_package(Package *package) {
  debug_log("package %s\n", package->package.value);
  for(int i = 0; i < arrlen(package->variables); i ++) {
    debug_log("Variable %s\n", package->variables[i].left->value.identifer_expr, 0);
  }
  for(int i = 0; i < arrlen(package->structs); i ++) {
    debug_log("struct %s\n", package->structs[i].name, 0);
  }
  for(int i = 0; i < arrlen(package->functions); i ++) {
    print_func_decl(package->functions[i], 0);
  }

}

int main() {


  
  size_t size = 0;
  char *input = read_file("./main.l", &size);


  Lexer lexer = {
    0,
    0,
    "./main.l",
    0,
    input,
    size
  };

  Token* token = NULL;
  lexer_tokenize(&lexer, &token);

  
  Parser p = {0};
  p.tokens = token;
  Package* package = parse_package(&p);
  
  print_package(package);

  gen_package(package);



  for (size_t i = 0; i < arrlen(token); i++) {
    free_token(&token[i]);
  }
  arrfree(token);
  free(input);
  return 0;
}
