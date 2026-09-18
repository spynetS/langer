#include "minunit.h"
#include "../src/lexer.h"
#include "../src/utils.h"
#include "../src/parser.h"
#include "../src/symbol_table.h"

#include <string.h>
#include <stdio.h>
#include <stdbool.h>

Package *get_package_file(const char* val) {
  Lexer lexer = {0};
  size_t size = 0;
  lexer.bytes = read_file(val, &size);
  lexer.bytes_length = size;

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);


  Parser p = {0};
  p.tokens = tokens;

  Package *package = parse_package(&p);
  return package;
}

Package *get_package_str(const char* val) {
  Lexer lexer = {0};
  size_t size = 0;
  lexer.bytes = (char*)val;
  lexer.bytes_length = strlen(val);

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);


  Parser p = {0};
  p.tokens = tokens;

  Package *package = parse_package(&p);
  return package;
}


MU_TEST(test_sym_var) {
  SymbolTable root = {0};

  symbol_table_package(&root, get_package_str(
    "package main;\n"
    "a: i16;\n"
    "b := 10;\n"
    "c: f64;\n"
  ));

  TypeResolver resolver = {0};
  resolver.scope = &root;
  symbol_table_resolve_types(&resolver, &root);

  SymbolTable *pkg = root.symbols[0]->scope;

  mu_check(pkg->symbols[0]->kind == SYMBOL_VARIABLE);
  mu_check(pkg->symbols[0]->type->kind == TYPE_I16);

  mu_check(pkg->symbols[1]->kind == SYMBOL_VARIABLE);
  mu_check(pkg->symbols[1]->type->kind == TYPE_I32);

  mu_check(pkg->symbols[2]->kind == SYMBOL_VARIABLE);
  mu_check(pkg->symbols[2]->type->kind == TYPE_F64);
}

MU_TEST(test_sym_var_inferred_types) {
  SymbolTable root = {0};

  symbol_table_package(&root, get_package_str(
    "package main;\n"
    "a := 10;\n"
    "b := 10.0;\n"
    "c := true;\n"
  ));

  TypeResolver resolver = {0};
  resolver.scope = &root;
  symbol_table_resolve_types(&resolver, &root);

  SymbolTable *pkg = root.symbols[0]->scope;

  mu_check(pkg->symbols[0]->type->kind == TYPE_I32);
  mu_check(pkg->symbols[1]->type->kind == TYPE_F32);
  mu_check(pkg->symbols[2]->type->kind == TYPE_BOOL);
}

MU_TEST(test_sym_struct) {
  SymbolTable root = {0};

  symbol_table_package(&root, get_package_str(
    "package main;\n"
    "struct Person {\n"
    "  age: int;\n"
    "height: f64;\n"
    "}"
  ));

  TypeResolver resolver = {0};
  resolver.scope = &root;
  symbol_table_resolve_types(&resolver, &root);

  SymbolTable *pkg = root.symbols[0]->scope;
  Symbol *person = pkg->symbols[0];

  //mu_check(person->kind == SYMBOL_TYPE);
  mu_check(person->type != NULL);
  mu_check(person->type->kind == TYPE_STRUCT);
  // TODO check members
  /* mu_check(person->scope != NULL); */
  /* mu_check(person->scope->symbols[0]->kind == SYMBOL_FIELD); */
  /* mu_check(person->scope->symbols[0]->type->kind == TYPE_I32); */

  /* mu_check(person->scope->symbols[1]->kind == SYMBOL_FIELD); */
  /* mu_check(person->scope->symbols[1]->type->kind == TYPE_F64 ); */
}

MU_TEST(test_sym_func) {
  SymbolTable root = {0};

  symbol_table_package(&root, get_package_str(
    "package main;\n"
    "func main(a: int, b: i16): f64 {\n"
    "  c: int = 10;\n"
    "}"
  ));

  TypeResolver resolver = {0};
  resolver.scope = &root;
  symbol_table_resolve_types(&resolver, &root);

  SymbolTable *pkg = root.symbols[0]->scope;
  Symbol *main = pkg->symbols[0];

  mu_check(main->kind == SYMBOL_FUNCTION);
  mu_check(main->type != NULL);
  mu_check(main->type->kind == TYPE_FUNCTION);

  Type *func = main->type;

  mu_check(func->Function.return_type->kind == TYPE_F64);

  mu_check(func->Function.parameters[0]->kind == TYPE_I32);
  mu_check(func->Function.parameters[1]->kind == TYPE_I16);

  mu_check(main->scope != NULL);
}

MU_TEST(test_sym_functest_sym_func_parameters) {
  SymbolTable root = {0};

  symbol_table_package(&root, get_package_str(
    "package main;\n"
    "func add(a: int, b: i16): i64 {\n"
    "}"
  ));

  TypeResolver resolver = {0};
  resolver.scope = &root;
  symbol_table_resolve_types(&resolver, &root);

  SymbolTable *pkg = root.symbols[0]->scope;
  Symbol *func = pkg->symbols[0];

  mu_check(func->kind == SYMBOL_FUNCTION);
  mu_check(func->type->kind == TYPE_FUNCTION);

  // Function type
  mu_check(func->type->Function.parameters[0]->kind == TYPE_I32);
  mu_check(func->type->Function.parameters[1]->kind == TYPE_I16);
  mu_check(func->type->Function.return_type->kind == TYPE_I64);

  // Parameter symbols
  mu_check(func->scope != NULL);

  mu_check(func->scope->symbols[0]->kind == SYMBOL_PARAMETER);
  mu_check(strcmp(func->scope->symbols[0]->key, "a") == 0);
  mu_check(func->scope->symbols[0]->type->kind == TYPE_I32);

  mu_check(func->scope->symbols[1]->kind == SYMBOL_PARAMETER);
  mu_check(strcmp(func->scope->symbols[1]->key, "b") == 0);
  mu_check(func->scope->symbols[1]->type->kind == TYPE_I16);
}


MU_TEST(test_sym_func_body) {
  SymbolTable root = {0};

  symbol_table_package(&root, get_package_str(
    "package main;\n"
    "func main(): int {\n"
    "  a: i16;\n"
    "  b: f64;\n"
    "  }\n"
  ));

  TypeResolver resolver = {0};
  resolver.scope = &root;
  symbol_table_resolve_types(&resolver, &root);

  SymbolTable *pkg = root.symbols[0]->scope;
  Symbol *func = pkg->symbols[0];

  mu_check(func->kind == SYMBOL_FUNCTION);
  mu_check(func->scope != NULL);

  mu_check(func->scope->symbols[0]->kind == SYMBOL_VARIABLE);
  mu_check(func->scope->symbols[0]->type->kind == TYPE_I16);

  mu_check(func->scope->symbols[1]->kind == SYMBOL_VARIABLE);
  mu_check(func->scope->symbols[1]->type->kind == TYPE_F64);
}

MU_TEST(test_sym_pointer) {
  SymbolTable root = {0};

  symbol_table_package(&root, get_package_str(
    "package main;\n"
    "a: *int;\n"
  ));

  TypeResolver resolver = {0};
  resolver.scope = &root;
  symbol_table_resolve_types(&resolver, &root);

  Symbol *a = root.symbols[0]->scope->symbols[0];
  
  mu_check(a->type->kind == TYPE_POINTER);
  mu_check(a->type->Pointer.base != NULL);
  mu_check(a->type->Pointer.base->kind == TYPE_I32);
}

MU_TEST(test_sym_array) {
  SymbolTable root = {0};

  symbol_table_package(&root, get_package_str(
    "package main;\n"
    "a: [10]int;\n"
  ));

  TypeResolver resolver = {0};
  resolver.scope = &root;
  symbol_table_resolve_types(&resolver, &root);

  Symbol *a = root.symbols[0]->scope->symbols[0];

  mu_check(a->type->kind == TYPE_ARRAY);
  mu_check(a->type->Array.length == 10);
  mu_check(a->type->Array.element != NULL);
  mu_check(a->type->Array.element->kind == TYPE_I32);
}

MU_TEST(test_sym_pointer_array) {
  SymbolTable root = {0};

  symbol_table_package(&root, get_package_str(
    "package main;\n"
    "a: [10]*i16;\n"
  ));

  TypeResolver resolver = {0};
  resolver.scope = &root;
  symbol_table_resolve_types(&resolver, &root);

  Type *type = root.symbols[0]->scope->symbols[0]->type;

  mu_check(type->kind == TYPE_ARRAY);
  mu_check(type->Array.length == 10);

  mu_check(type->Array.element->kind == TYPE_POINTER);
  mu_check(type->Array.element->Pointer.base->kind == TYPE_I16);
}

MU_TEST(test_sym_named_struct_reference) {
  SymbolTable root = {0};

  symbol_table_package(&root, get_package_str(
    "package main;\n"
    "struct Person {\n"
    "  age: int;\n"
    "}\n"
    "func foo(p: Person): Person {\n"
    "}\n"
  ));

  TypeResolver resolver = {0};
  resolver.scope = &root;
  symbol_table_resolve_types(&resolver, &root);

  SymbolTable *pkg = root.symbols[0]->scope;

  Symbol *person = pkg->symbols[0];
  Symbol *foo = pkg->symbols[1];

  mu_check(person->type->kind == TYPE_STRUCT);
  mu_check(foo->type->kind == TYPE_FUNCTION);

  Type *func = foo->type;

  mu_check(func->Function.parameters[0]->kind == TYPE_STRUCT);
  mu_check(func->Function.return_type->kind == TYPE_STRUCT);

  //If named type references resolve to the canonical Type:
  mu_check(func->Function.parameters[0] == person->type);
  mu_check(func->Function.return_type == person->type);
}

MU_TEST(test_sym_scope_tree) {
  SymbolTable root = {0};

  symbol_table_package(&root, get_package_str(
    "package main;\n"
    "struct Person {\n"
    "  age: int;\n"
    "}\n"
    "func main(x: int): void {\n"
    "  y: i16;\n"
    "}"
  ));

  TypeResolver resolver = {0};
  resolver.scope = &root;
  symbol_table_resolve_types(&resolver, &root);

  mu_check(root.symbols[0]->kind == SYMBOL_PACKAGE);

  Symbol *pkg = root.symbols[0];

  //mu_check(pkg->scope != NULL);
  /* mu_check(pkg->scope->symbols[0]->kind == SYMBOL_TYPE); */
  /* mu_check(pkg->scope->symbols[1]->kind == SYMBOL_FUNCTION); */

  Symbol *person = pkg->scope->symbols[0];
  Symbol *main = pkg->scope->symbols[1];

  /* mu_check(person->scope != NULL); */
  /* mu_check(person->scope->symbols[0]->kind == SYMBOL_FIELD); */

  mu_check(main->scope != NULL);
  mu_check(main->scope->symbols[0]->kind == SYMBOL_PARAMETER);
  mu_check(main->scope->symbols[1]->kind == SYMBOL_VARIABLE);
}


MU_TEST_SUITE(test_suite_symbol_table) {
  /* Variables */
  MU_RUN_TEST(test_sym_var);
  MU_RUN_TEST(test_sym_var_inferred_types);

  /* Structs */
  MU_RUN_TEST(test_sym_struct);
  MU_RUN_TEST(test_sym_named_struct_reference);

  /* Functions */
  MU_RUN_TEST(test_sym_func);
  //  MU_RUN_TEST(test_sym_func_parameters);
  MU_RUN_TEST(test_sym_func_body);

  /* /\* Compound types *\/ */
  MU_RUN_TEST(test_sym_pointer);
  /* MU_RUN_TEST(test_sym_array); */
  /* MU_RUN_TEST(test_sym_pointer_array); */

  /* /\* Scopes *\/ */
  MU_RUN_TEST(test_sym_scope_tree);

}
