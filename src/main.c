#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include "lexer.h"
#include "parser.h"
#define STB_DS_IMPLEMENTATION
#include "stb_ds.h"
#include "utils.h"

// lexer
// parser
// resolver
// checker
// generator

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
  Program* program = parse_program(&p);

  
  debug_log("package %s\n", program->package.value);
  for(int i = 0; i < arrlen(program->variables); i ++) {
    debug_log("Variable %s\n", program->variables[i].left->value.identifer_expr, 0);
  }
  for(int i = 0; i < arrlen(program->functions); i ++) {
    print_func_decl(program->functions[i], 0);
  }




  for (size_t i = 0; i < arrlen(token); i++) {
    printf("%s ", token[i].lexeme);
    free_token(&token[i]);
  }

  arrfree(token);
  free(input);

  return 0;
}
