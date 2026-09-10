#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include "lexer.h"
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
  tokenize(&lexer, &token);

  for (size_t i = 0; i < arrlen(token); i++) {
    printf("%s ",token[i].lexeme);
  }

  

  return 0;
}
