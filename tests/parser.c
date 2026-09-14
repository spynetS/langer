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

MU_TEST(test_decl) {
  Parser p = {0};
  p.tokens = get_tokens("alfred : int");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_DECL);
}

MU_TEST(test_assign0) {
  Parser p = {0};
  p.tokens = get_tokens("alfred : int = 67");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_DECL);
  mu_check(e->value.decl_expr.initlizer != NULL);
  mu_check(e->value.decl_expr.type != NULL);
  mu_check(e->value.decl_expr.type->kind == AST_TYPE_I32);
  mu_check(e->value.decl_expr.initlizer->kind == AST_INTEGER_LITERAL);
  mu_check(e->value.decl_expr.initlizer->value.int_expr.value == 67);
}

MU_TEST(test_assign1) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := 67");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_DECL);
  mu_check(e->value.decl_expr.initlizer != NULL);
  mu_check(e->value.decl_expr.initlizer->kind == AST_INTEGER_LITERAL);
  mu_check(e->value.decl_expr.initlizer->value.int_expr.value == 67);
}

MU_TEST(test_assign_expr) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := 67+69*2/4");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_DECL);
  mu_check(e->value.decl_expr.initlizer != NULL);
  mu_check(e->value.decl_expr.initlizer->kind == AST_BINARY);
}

MU_TEST(test_assign_expr2) {
  Parser p = {0};
  p.tokens = get_tokens("alfred :int = 67+69*2/4");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_DECL);
  mu_check(e->value.decl_expr.initlizer != NULL);
  mu_check(e->value.decl_expr.type != NULL);
  mu_check(e->value.decl_expr.type->kind == AST_TYPE_I32);
  mu_check(e->value.decl_expr.initlizer->kind == AST_BINARY);
}


MU_TEST(test_assign2) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := 67.69");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_DECL);
  mu_check(e->value.decl_expr.initlizer->kind == AST_FLOAT_LITERAL);
  mu_check((int)e->value.decl_expr.initlizer->value.float_expr.value*100 == (int)67.69*100);
}


MU_TEST(test_assignidentifer) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := alfred2");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_DECL);
  mu_check(e->value.decl_expr.initlizer->kind == AST_IDENTIFER);
  mu_check(strcmp(e->value.decl_expr.initlizer->value.identifer_expr.value, "alfred2") == 0);
}

MU_TEST(test_assignstring) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := \"Alfred\"");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_DECL);
  mu_check(e->value.decl_expr.initlizer->kind == AST_STRING_LITERAL);
  mu_check(strcmp(e->value.decl_expr.initlizer->value.string_expr.value, "\"Alfred\"") == 0);
}

MU_TEST(test_plus) {
  Parser p = {0};
  p.tokens = get_tokens("1+1");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_BINARY);
  mu_check(e->value.binary_expr.operator.kind == TOKEN_PLUS);
}

MU_TEST(test_minus) {
  Parser p = {0};
  p.tokens = get_tokens("1-1");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_BINARY);
  mu_check(e->value.binary_expr.operator.kind == TOKEN_MINUS);
}

MU_TEST(test_multiply) {
  Parser p = {0};
  p.tokens = get_tokens("1+2*3/4");

  Ast* e = parse_expression(&p);
  // 1 + ((2 * 3) / 4)
  mu_check(e != NULL);
  mu_check(e->kind == AST_BINARY);

  // Root: +
  mu_check(e->value.binary_expr.operator.kind == TOKEN_PLUS);

  Ast *right = e->value.binary_expr.right;
  mu_check(right != NULL);
  mu_check(right->kind == AST_BINARY);

  // Right side: (2 * 3) / 4
  mu_check(right->value.binary_expr.operator.kind == TOKEN_SLASH);

  Ast *multiply = right->value.binary_expr.left;
  mu_check(multiply != NULL);
  mu_check(multiply->kind == AST_BINARY);

  // (2 * 3)
  mu_check(multiply->value.binary_expr.operator.kind == TOKEN_STAR);

  mu_check(multiply->value.binary_expr.left->kind == AST_INTEGER_LITERAL);
  mu_check(multiply->value.binary_expr.left->value.int_expr.value == 2);

  mu_check(multiply->value.binary_expr.right->kind == AST_INTEGER_LITERAL);
  mu_check(multiply->value.binary_expr.right->value.int_expr.value == 3);

  // / 4
  mu_check(right->value.binary_expr.right->kind == AST_INTEGER_LITERAL);
  mu_check(right->value.binary_expr.right->value.int_expr.value == 4);

  // + 1
  mu_check(e->value.binary_expr.left->kind == AST_INTEGER_LITERAL);
  mu_check(e->value.binary_expr.left->value.int_expr.value == 1);
}

MU_TEST(test_var_assign) {
  Parser p = {0};
  p.tokens = get_tokens("asd = asd2");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_ASSIGN);
}

MU_TEST(test_or) {
  Parser p = {0};
  p.tokens = get_tokens("foo || bar");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_BINARY);
  mu_check(e->value.binary_expr.operator.kind == TOKEN_OR);
}

MU_TEST(test_and) {
  Parser p = {0};
  p.tokens = get_tokens("foo && bar");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_BINARY);
  mu_check(e->value.binary_expr.operator.kind == TOKEN_AND);
}



MU_TEST(test_return) {
  Parser p = {0};
  p.tokens = get_tokens("return 0");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_RETURN);
  mu_check(e->value.return_stmt.value->kind == AST_INTEGER_LITERAL);
}

MU_TEST(test_return_expr) {
  Parser p = {0};
  p.tokens = get_tokens("return 1+2+asd");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_RETURN);
  mu_check(e->value.return_stmt.value->kind == AST_BINARY);
}

MU_TEST(test_package) {
  Parser p = {0};
  p.tokens = get_tokens("package main");

  Ast* e = parse_package(&p);
  mu_check(e->kind == AST_PACKAGE);
  mu_check(strcmp(e->value.package_stmt.value, "main") == 0);
}

MU_TEST(test_package2) {
  Parser p = {0};
  p.tokens = get_tokens("package foo.bar.bizz");

  Ast* e = parse_package(&p);
  mu_check(e->kind == AST_PACKAGE);
  mu_check(strcmp(e->value.package_stmt.value, "foo.bar.bizz") == 0);
}


MU_TEST(test_package_fail) {
  Parser p = {0};
  p.tokens = get_tokens("package 1.2");

  Ast* e = parse_package(&p);
  mu_check(e->kind == AST_INVALID);
}


MU_TEST(test_program) {
  Parser p = {0};
  p.tokens = get_tokens("package foo.bar.bazz;\nasd :int = 10+10; \n func main(a: int, b: int): float { return 0; }");

  Program* program = parse_program(&p);
  mu_check(arrlen(program->variables) == 1);
  mu_check(program->variables[0].left->kind == AST_IDENTIFER);
  mu_check(arrlen(program->functions) == 1);
}


MU_TEST(test_struct) {
  Parser p = {0};
  p.tokens = get_tokens("struct Foo {\na:int;\nb:int\n}");

  Ast* struc = parse_struct_decl(&p);
  mu_check(struc->kind == AST_STRUCT_DECL);
  mu_check(struc->value.struct_decl.name != NULL);
  mu_check(strcmp(struc->value.struct_decl.name, "Foo") == 0);

  mu_check(arrlen(struc->value.struct_decl.members) == 2);
  mu_check(struc->value.struct_decl.members[0]->kind = AST_VAR_DECL);
  mu_check(struc->value.struct_decl.members[0]->value.decl_expr.left->kind = AST_IDENTIFER);
  mu_check(strcmp(struc->value.struct_decl.members[0]->value.decl_expr.left->value.identifer_expr.value, "a") == 0);

  mu_check(struc->value.struct_decl.members[1]->kind = AST_VAR_DECL);
  mu_check(struc->value.struct_decl.members[1]->value.decl_expr.left->kind = AST_IDENTIFER);
  mu_check(strcmp(struc->value.struct_decl.members[1]->value.decl_expr.left->value.identifer_expr.value, "b") == 0);
  
}



MU_TEST_SUITE(test_suite_parser) {
  MU_RUN_TEST(test_decl);
  MU_RUN_TEST(test_assign0);
  MU_RUN_TEST(test_assign1);
  MU_RUN_TEST(test_assign_expr);
  MU_RUN_TEST(test_assign_expr2);
  MU_RUN_TEST(test_assign2);
  MU_RUN_TEST(test_assignidentifer);
  MU_RUN_TEST(test_assignstring);

  MU_RUN_TEST(test_plus);
  MU_RUN_TEST(test_minus);
  MU_RUN_TEST(test_multiply);

  MU_RUN_TEST(test_var_assign);

  MU_RUN_TEST(test_or);
  MU_RUN_TEST(test_and);

  MU_RUN_TEST(test_return);
  MU_RUN_TEST(test_return_expr);
  
  MU_RUN_TEST(test_package);
  MU_RUN_TEST(test_package2);
  MU_RUN_TEST(test_package_fail);

  MU_RUN_TEST(test_program);

  MU_RUN_TEST(test_struct);
}
