#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include "lexer.h"
#include "parser.h"
#include "llvm.h"
#include "symbol_table.h"
#include "type_resolver.h"
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
  for(int i = 0; i < arrlen(package->declarations); i ++) {
    print_ast(package->declarations[i], 0);
  }
}

void handle_args(int argc, char** argv, char*** files) {
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-h") == 0) {
      printf("Hello world!\n");
      exit(0);
    } else {
      arrput(*files, argv[i]);
    }
  }
}

int main(int argc, char** argv) {

  char** files = NULL;
  handle_args(argc, argv, &files);

  SymbolTable root = {0};
  root.symbols = NULL;

  for (int i = 0; i < arrlen(files); i++) {
    size_t size = 0;
    char *input = read_file(files[i], &size);


    Lexer lexer = {
      0,
      0,
      files[i],
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

    symbol_table_package(&root, package);
    printf("=======START RESOLVER======\n");
    TypeResolver resolver = {0};
    resolver.scope = &root;
    symbol_table_resolve_types(&resolver, &root);
    printf("====AFTER RESOLVED====\n");
    print_symbol_table(&root, 0);
    printf("==========\n");
    print_package(package);
    gen_package(package);



    for (size_t i = 0; i < arrlen(token); i++) {
      free_token(&token[i]);
    }
    arrfree(token);
    free(input);
  }
  return 0;
}
