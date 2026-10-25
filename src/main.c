#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "lexer.h"
#include "parser.h"
#include "llvm.h"
#include "symbol_table.h"
#include "type_resolver.h"
#define STB_DS_IMPLEMENTATION
#include "../include/stb_ds.h"
#include "utils.h"
#include "../include/sb.h"


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
      debug_log("Hello world!\n");
      exit(0);
    } else {
      arrput(*files, argv[i]);
    }
  }
}

int compile_backend(char** files) {
  StringBuilder	*builder = sb_create();
  sb_appendf(builder, "clang ");
  for(int i = 0; i < arrlen(files); i++) {
    sb_appendf(builder, "%s ", files[i]);
  }
  sb_appendf(builder, "-o main");

  int status = system(sb_concat(builder));

  if (status == -1) {
    perror("system");
    return 1;
  }

  sb_free(builder);
  return 0;
}

int main(int argc, char** argv) {

  char **files = NULL;
  handle_args(argc, argv, &files);
  Package** packages = NULL;
  SymbolTable** symbol_tables = NULL;

  SymbolTable root = {0};
  root.symbols = NULL;

  TypeResolver resolver = {0};
  resolver.scope = &root;
  debug_log("### LEXER AND PARSER ###\n");
  for (int i = 0; i < arrlen(files); i++) {
    size_t size = 0;
    char *input = read_file(files[i], &size);
    debug_log("compiling %s...\n", files[i]);

    Lexer lexer = { 0, 0, files[i], 0, input, size};

    Token* token = NULL;
    lexer_tokenize(&lexer, &token);
  
    Parser p = {0};
    p.tokens = token;
    Package* package = parse_package(&p);
    print_package(package);

    SymbolTable *table = symbol_table_package(&root, package, package->package.value);
    
    arrput(packages, package);
    arrput(symbol_tables, table);
    print_package(package);

    /* for (size_t i = 0; i < arrlen(token); i++) { */
    /*   free_token(&token[i]); */
    /* } */
    /* arrfree(token); */
    free(input);
  }
  debug_log("===after parsing====\n");
  print_symbol_table(&root,0);


  debug_log("### TYPE RESOLVER ###\n");
  for (int i = 0; i < arrlen(files); i++) {
    Package *package = packages[i];

    // here we don't care about the individual expressions
    resolver.resolve_expr = false;
    resolver.scope = &root;

    debug_log("=======START RESOLVER %s======\n", package->package.value);
    symbol_table_resolve_types(&resolver, &root);    
    debug_log("====AFTER RESOLVED====\n");
    print_symbol_table(&root, 0);
    debug_log("==========\n");

    // for individual varaibles we want to check expressions? IDK why directly
    
    resolver.resolve_expr = true;
    for(size_t i = 0; i < arrlen(root.symbols); i ++) {
      if(strcmp(root.symbols[i]->key, package->package.value) == 0)
        resolver.scope = root.symbols[i]->scope;
    }
    resolver.scope = &root;
    // now we want to check all types
    debug_log("====Start RESOLVED package '%s'====\n", package->package.value);
    type_check_package(&resolver, package);
    debug_log("==========\n");

    print_package(package);
  }

  char **irl_files = NULL;
  
  debug_log("### LLVM GENERATIONS ###\n");
  for (int i = 0; i < arrlen(files); i++) {
    Package *package = packages[i];
    char *file_name = gen_package(package, symbol_tables[i]);
    arrput(irl_files, file_name);
  }

  int status = compile_backend(irl_files);

  return 0;
}
