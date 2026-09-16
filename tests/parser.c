#include "minunit.h"
#include "../src/parser.h"
#include "../src/lexer.h"
#include "../src/ast.h"
#include "../src/utils.h"

#include <string.h>
#include <stdio.h>
#include <stdbool.h>


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
  mu_check(e->kind == AST_VAR_DECL);
}

MU_TEST(test_decl_struct) {
  Parser p = {0};
  p.tokens = get_tokens("alfred : Person");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.type->kind == AST_TYPE_NAME);
}

MU_TEST(test_decl_struct_ptr) {
  Parser p = {0};
  p.tokens = get_tokens("alfred : *Person");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.type->kind == AST_TYPE_POINTER);
  mu_check(e->value.variable_decl.type->value.pointer_type.to->kind == AST_TYPE_NAME);
  p = (Parser){0};
  p.tokens = get_tokens("alfred : ***Person");

  e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.type->kind == AST_TYPE_POINTER);
  mu_check(e->value.variable_decl.type->value.pointer_type.to->kind == AST_TYPE_POINTER);
  mu_check(e->value.variable_decl.type->value.pointer_type.to->value.pointer_type.to->kind == AST_TYPE_POINTER);
  mu_check(e->value.variable_decl.type->value.pointer_type.to->value.pointer_type.to->value.pointer_type.to->kind == AST_TYPE_NAME);
  mu_check(strcmp(e->value.variable_decl.type->value.pointer_type.to->value.pointer_type.to->value.pointer_type.to->value.named_type.name, "Person") == 0);
}




MU_TEST(test_assign0) {
  Parser p = {0};
  p.tokens = get_tokens("alfred : int = 67");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.initlizer != NULL);
  mu_check(e->value.variable_decl.type != NULL);
  mu_check(e->value.variable_decl.type->kind == AST_TYPE_I32);
  mu_check(e->value.variable_decl.initlizer->kind == AST_INTEGER_LITERAL);
  mu_check(e->value.variable_decl.initlizer->value.int_expr.value == 67);
}

MU_TEST(test_assign1) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := 67");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.initlizer != NULL);
  mu_check(e->value.variable_decl.initlizer->kind == AST_INTEGER_LITERAL);
  mu_check(e->value.variable_decl.initlizer->value.int_expr.value == 67);
}

MU_TEST(test_assign_expr) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := 67+69*2/4");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.initlizer != NULL);
  mu_check(e->value.variable_decl.initlizer->kind == AST_BINARY);
}

MU_TEST(test_assign_expr2) {
  Parser p = {0};
  p.tokens = get_tokens("alfred :int = 67+69*2/4");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.initlizer != NULL);
  mu_check(e->value.variable_decl.type != NULL);
  mu_check(e->value.variable_decl.type->kind == AST_TYPE_I32);
  mu_check(e->value.variable_decl.initlizer->kind == AST_BINARY);
}


MU_TEST(test_assign2) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := 67.69");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.initlizer->kind == AST_FLOAT_LITERAL);
  mu_check((int)e->value.variable_decl.initlizer->value.float_expr.value*100 == (int)67.69*100);
}


MU_TEST(test_assignidentifer) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := alfred2");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.initlizer->kind == AST_IDENTIFER);
  mu_check(strcmp(e->value.variable_decl.initlizer->value.identifer_expr.value, "alfred2") == 0);
}

MU_TEST(test_assignstring) {
  Parser p = {0};
  p.tokens = get_tokens("alfred := \"Alfred\"");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.initlizer->kind == AST_STRING_LITERAL);
  mu_check(strcmp(e->value.variable_decl.initlizer->value.string_expr.value.data, "\"Alfred\"") == 0);
}

MU_TEST(test_plus) {
  Parser p = {0};
  p.tokens = get_tokens("1+1");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_BINARY);
  mu_check(e->value.binary_expr.operator == TOKEN_PLUS);
}

MU_TEST(test_minus) {
  Parser p = {0};
  p.tokens = get_tokens("1-1");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_BINARY);
  mu_check(e->value.binary_expr.operator == TOKEN_MINUS);
}

MU_TEST(test_multiply) {
  Parser p = {0};
  p.tokens = get_tokens("1+2*3/4");

  Ast* e = parse_expression(&p);
  // 1 + ((2 * 3) / 4)
  mu_check(e != NULL);
  mu_check(e->kind == AST_BINARY);

  // Root: +
  mu_check(e->value.binary_expr.operator == TOKEN_PLUS);

  Ast *right = e->value.binary_expr.right;
  mu_check(right != NULL);
  mu_check(right->kind == AST_BINARY);

  // Right side: (2 * 3) / 4
  mu_check(right->value.binary_expr.operator == TOKEN_SLASH);

  Ast *multiply = right->value.binary_expr.left;
  mu_check(multiply != NULL);
  mu_check(multiply->kind == AST_BINARY);

  // (2 * 3)
  mu_check(multiply->value.binary_expr.operator == TOKEN_STAR);

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
  mu_check(e->value.binary_expr.operator == TOKEN_OR);
}

MU_TEST(test_and) {
  Parser p = {0};
  p.tokens = get_tokens("foo && bar");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_BINARY);
  mu_check(e->value.binary_expr.operator == TOKEN_AND);
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

  Ast* e = parse_package_stmt(&p);
  mu_check(e->kind == AST_PACKAGE);
  mu_check(strcmp(e->value.package_stmt.value, "main") == 0);
}

MU_TEST(test_package2) {
  Parser p = {0};
  p.tokens = get_tokens("package foo.bar.bizz");

  Ast* e = parse_package_stmt(&p);
  mu_check(e->kind == AST_PACKAGE);
  mu_check(strcmp(e->value.package_stmt.value, "foo.bar.bizz") == 0);
}


MU_TEST(test_package_fail) {
  Parser p = {0};
  p.tokens = get_tokens("package 1.2");

  Ast* e = parse_package_stmt(&p);
  mu_check(e->kind == AST_INVALID);
}


MU_TEST(test_program_package) {
  Parser p = {0};
  p.tokens = get_tokens("package foo.bar.bazz;\nasd :int = 10+10; \n func main(a: int, b: int): float { return 0; }");

  Package* package = parse_package(&p);
  mu_check(arrlen(package->declarations) == 2);
  mu_check(package->declarations[0]->value.variable_decl.left->kind == AST_IDENTIFER);
  mu_check(arrlen(package->declarations) == 2);
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
  mu_check(struc->value.struct_decl.members[0]->value.variable_decl.left->kind = AST_IDENTIFER);
  mu_check(strcmp(struc->value.struct_decl.members[0]->value.variable_decl.left->value.identifer_expr.value, "a") == 0);

  mu_check(struc->value.struct_decl.members[1]->kind = AST_VAR_DECL);
  mu_check(struc->value.struct_decl.members[1]->value.variable_decl.left->kind = AST_IDENTIFER);
  mu_check(strcmp(struc->value.struct_decl.members[1]->value.variable_decl.left->value.identifer_expr.value, "b") == 0);

  p = (Parser){0};
  p.tokens = get_tokens("struct Foo {\nprivate a:int;\npublic b:int\n}");

  struc = parse_struct_decl(&p);
  mu_check(struc->kind == AST_STRUCT_DECL);
  mu_check(struc->value.struct_decl.name != NULL);
  mu_check(strcmp(struc->value.struct_decl.name, "Foo") == 0);

  mu_check(arrlen(struc->value.struct_decl.members) == 2);
  mu_check(struc->value.struct_decl.members[0]->kind = AST_VAR_DECL);
  mu_check(struc->value.struct_decl.members[0]->value.variable_decl.left->kind = AST_IDENTIFER);
  mu_check(strcmp(struc->value.struct_decl.members[0]->value.variable_decl.left->value.identifer_expr.value, "a") == 0);

  mu_check(struc->value.struct_decl.members[1]->kind = AST_VAR_DECL);
  mu_check(struc->value.struct_decl.members[1]->value.variable_decl.left->kind = AST_IDENTIFER);
  mu_check(strcmp(struc->value.struct_decl.members[1]->value.variable_decl.left->value.identifer_expr.value, "b") == 0);

}

MU_TEST(test_function_decl) {
  Parser p = {0};
  p.tokens = get_tokens("func foo(a :int, b: string): void ");

  Ast* e = parse_function(&p);
  mu_check(e->kind == AST_FUNC_DECL);
    mu_check(e->value.function_decl.body == NULL);
}

MU_TEST(test_function) {
  Parser p = {0};
  p.tokens = get_tokens("func foo(a :int, b: string): void {\n\treturn 0\n}");

  Ast* e = parse_function(&p);
  mu_check(e->kind == AST_FUNC_DECL);
  mu_check(e->value.function_decl.body != NULL);
}

MU_TEST(test_extern_function_decl) {
  Parser p = {0};
  p.tokens = get_tokens("extern func foo(a :int, b: string): void ");

  Ast* e = parse_function(&p);
  mu_check(e->kind == AST_FUNC_DECL);
  mu_check(e->value.function_decl.body == NULL);
  mu_check(e->value.function_decl.is_extern == true);
}

MU_TEST(test_call) {
  Parser p = {0};
  p.tokens = get_tokens("foo()");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_CALL);
  mu_check(e->value.call_expr.left->kind == AST_IDENTIFER);
  mu_check(strcmp(e->value.call_expr.left->value.identifer_expr.value, "foo") == 0);
}

MU_TEST(test_member_access) {
  Parser p = {0};
  p.tokens = get_tokens("foo.bar");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_MEMBER);
  mu_check(e->value.member_expr.left->kind == AST_IDENTIFER);
  mu_check(strcmp(e->value.member_expr.left->value.identifer_expr.value, "foo") == 0);
  mu_check(strcmp(e->value.member_expr.member, "bar") == 0);
}

MU_TEST(test_member_access2) {
  Parser p = {0};
  p.tokens = get_tokens("foo.bar.bizz");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_MEMBER);
  mu_check(e->value.member_expr.left->kind == AST_MEMBER);
  mu_check(e->value.member_expr.left->value.member_expr.left->kind == AST_IDENTIFER);
  mu_check(strcmp(e->value.member_expr.left->value.member_expr.member, "bar") == 0);
}

MU_TEST(test_visibility_decl) {
  Parser p = {0};
  p.tokens = get_tokens("alfred : int");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.visibility == VIS_PRIVATE);

  p = (Parser){0};
  p.tokens = get_tokens("private alfred : int");
  e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.visibility == VIS_PRIVATE);

  p = (Parser){0};
  p.tokens = get_tokens("public alfred : int");
  e = parse_stmt(&p);
  mu_check(e->kind == AST_VAR_DECL);
  mu_check(e->value.variable_decl.visibility == VIS_PUBLIC);

  p = (Parser){0};
  p.tokens = get_tokens("func main(): int");
  e = parse_function(&p);
  mu_check(e->kind == AST_FUNC_DECL);
  mu_check(e->value.function_decl.visibility == VIS_PRIVATE);

  p = (Parser){0};
  p.tokens = get_tokens("private func main(): int");
  p.pos++;
  e = parse_function(&p);
  mu_check(e->kind == AST_FUNC_DECL);
  mu_check(e->value.function_decl.visibility == VIS_PRIVATE);

  
  p = (Parser){0};
  p.tokens = get_tokens("public func main(): int");
  // FIXME this is because the position should not be on the public token
  p.pos ++;
  
  e = parse_function(&p);
  mu_check(e->kind == AST_FUNC_DECL);
  mu_check(e->value.function_decl.visibility == VIS_PUBLIC);


  p = (Parser){0};
  p.tokens = get_tokens("struct Person {}");
  e = parse_struct_decl(&p);
  mu_check(e->kind == AST_STRUCT_DECL);
  mu_check(e->value.struct_decl.visibility == VIS_PRIVATE);

  p = (Parser){0};
  p.tokens = get_tokens("private struct Person {}");
  p.pos++;
  e = parse_struct_decl(&p);
  mu_check(e->kind == AST_STRUCT_DECL);
  mu_check(e->value.struct_decl.visibility == VIS_PRIVATE);

  p = (Parser){0};
  p.tokens = get_tokens("public struct Person {}");
  p.pos++;
  e = parse_struct_decl(&p);
  mu_check(e->kind == AST_STRUCT_DECL);
  mu_check(e->value.struct_decl.visibility == VIS_PUBLIC);
}

MU_TEST(test_unary) {
  Parser p = {0};
  p.tokens = get_tokens("-1");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_UNARY);
  mu_check(e->value.unary_expr.operator == TOKEN_MINUS);
  mu_check(e->value.unary_expr.operand->kind == AST_INTEGER_LITERAL);

  p = (Parser){0};
  p.tokens = get_tokens("-asd");
  e = parse_expression(&p);
  mu_check(e->kind == AST_UNARY);
  mu_check(e->value.unary_expr.operator == TOKEN_MINUS);
  mu_check(e->value.unary_expr.operand->kind == AST_IDENTIFER);

  p = (Parser){0};
  p.tokens = get_tokens("*asd");
  e = parse_expression(&p);
  mu_check(e->kind == AST_UNARY);
  mu_check(e->value.unary_expr.operator == TOKEN_STAR);
  mu_check(e->value.unary_expr.operand->kind == AST_IDENTIFER);

  p = (Parser){0};
  p.tokens = get_tokens("&asd");
  e = parse_expression(&p);
  mu_check(e->kind == AST_UNARY);
  mu_check(e->value.unary_expr.operator == TOKEN_AMPER);
  mu_check(e->value.unary_expr.operand->kind == AST_IDENTIFER);

  p = (Parser){0};
  p.tokens = get_tokens("&&asd");
  e = parse_expression(&p);
  mu_check(e->kind == AST_UNARY);
  mu_check(e->value.unary_expr.operator == TOKEN_AMPER);
  mu_check(e->value.unary_expr.operand->kind == AST_UNARY);
  mu_check(e->value.unary_expr.operand->value.unary_expr.operand->kind == AST_IDENTIFER);
}

MU_TEST(test_index) {
  Parser p = {0};
  p.tokens = get_tokens("asd[0]");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_INDEX);
  mu_check(e->value.index_expr.left->kind == AST_IDENTIFER);
  mu_check(strcmp(e->value.index_expr.left->value.identifer_expr.value, "asd") == 0);
  mu_check(e->value.index_expr.index->kind == AST_INTEGER_LITERAL);

  p = (Parser){0};
  p.tokens = get_tokens("asd[1+1]");
  e = parse_expression(&p);
  mu_check(e->kind == AST_INDEX);
  mu_check(e->value.index_expr.left->kind == AST_IDENTIFER);
  mu_check(e->value.index_expr.index->kind == AST_BINARY);

  p = (Parser){0};
  p.tokens = get_tokens("asd[asd]");
  e = parse_expression(&p);
  mu_check(e->kind == AST_INDEX);
  mu_check(e->value.index_expr.left->kind == AST_IDENTIFER);
  mu_check(e->value.index_expr.index->kind == AST_IDENTIFER);

  
  p = (Parser){0};
  p.tokens = get_tokens("asd[foo[1+1]]");
  e = parse_expression(&p);
  mu_check(e->kind == AST_INDEX);
  mu_check(e->value.index_expr.left->kind == AST_IDENTIFER);
  mu_check(e->value.index_expr.index->kind == AST_INDEX);
  mu_check(e->value.index_expr.index->value.index_expr.index->kind == AST_BINARY);

}

MU_TEST(test_bool_literal) {
  Parser p = {0};
  p.tokens = get_tokens("true");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_BOOL_LITERAL);
  mu_check(e->value.bool_expr.value == true);

  p = (Parser){0};
  p.tokens = get_tokens("false");
  e = parse_expression(&p);
  mu_check(e->kind == AST_BOOL_LITERAL);
  mu_check(e->value.bool_expr.value == false);
}

MU_TEST(test_char_literal) {
  Parser p = {0};
  p.tokens = get_tokens("'a'");

  Ast* e = parse_expression(&p);
  mu_check(e->kind == AST_CHAR_LITERAL);
  //mu_check(e->value.bool_expr.value == true);

  p = (Parser){0};
  p.tokens = get_tokens("'\n'");
  e = parse_expression(&p);
  mu_check(e->kind == AST_CHAR_LITERAL);
  //  mu_check(e->value.bool_expr.value == false);
}

MU_TEST(test_if) {
  Parser p = {0};
  p.tokens = get_tokens("if 1 == 2 {\n}");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_IF);
  mu_check(e->value.if_stmt.condition->kind == AST_BINARY);
  mu_check(e->value.if_stmt.condition->value.binary_expr.operator == TOKEN_EQUAL);
  mu_check(e->value.if_stmt.body != NULL);
  mu_check(e->value.if_stmt.body->kind == AST_BLOCK);

  p = (Parser){0};
  p.tokens = get_tokens("if true && false {\n}");
  e = parse_stmt(&p);
  mu_check(e->kind == AST_IF);
  mu_check(e->value.if_stmt.condition->kind == AST_BINARY);
  mu_check(e->value.if_stmt.condition->value.binary_expr.operator == TOKEN_AND);
  mu_check(e->value.if_stmt.condition->value.binary_expr.left->kind == AST_BOOL_LITERAL);
  mu_check(e->value.if_stmt.condition->value.binary_expr.right->kind == AST_BOOL_LITERAL);
  mu_check(e->value.if_stmt.body != NULL);
  mu_check(e->value.if_stmt.body->kind == AST_BLOCK);


  p = (Parser){0};
  p.tokens = get_tokens("if true || false {\n} \n else if true {\n} else {\n}");
  e = parse_stmt(&p);
  mu_check(e->kind == AST_IF);
  mu_check(e->value.if_stmt.else_if_stmt->kind == AST_IF);
  mu_check(e->value.if_stmt.condition->value.binary_expr.operator == TOKEN_OR);
  mu_check(e->value.if_stmt.else_if_stmt->value.if_stmt.condition->kind == AST_BOOL_LITERAL);
  mu_check(e->value.if_stmt.body->kind == AST_BLOCK);
  
  mu_check(e->value.if_stmt.else_body == NULL);
  mu_check(e->value.if_stmt.else_if_stmt->value.if_stmt.else_body != NULL);
  mu_check(e->value.if_stmt.else_if_stmt->value.if_stmt.else_body->kind == AST_BLOCK);
}

MU_TEST(test_conditions) {
  Parser p = {0};
  p.tokens = get_tokens("true || false");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_BINARY);
  mu_check(e->value.binary_expr.left->kind == AST_BOOL_LITERAL);
  mu_check(e->value.binary_expr.right->kind == AST_BOOL_LITERAL);
  mu_check(e->value.binary_expr.operator == TOKEN_OR);
  /* mu_check(e->value.if_stmt.condition->kind == AST_BINARY); */
  /* mu_check(e->value.if_stmt.condition->value.binary_expr.operator == TOKEN_EQUAL); */
  /* mu_check(e->value.if_stmt.body != NULL); */
  /* mu_check(e->value.if_stmt.body->kind == AST_BLOCK); */

  p = (Parser){0};
  p.tokens = get_tokens("true && false");
  e = parse_stmt(&p);
  mu_check(e->kind == AST_BINARY);
  mu_check(e->value.binary_expr.left->kind == AST_BOOL_LITERAL);
  mu_check(e->value.binary_expr.right->kind == AST_BOOL_LITERAL);
  mu_check(e->value.binary_expr.operator == TOKEN_AND);

}


MU_TEST(test_cast) {
  Parser p = {0};
  p.tokens = get_tokens("(f32)x");

  Ast* e = parse_stmt(&p);
  mu_check(e->kind == AST_CAST);
  mu_check(e->value.cast_expr.expression->kind == AST_IDENTIFER);
  mu_check(e->value.cast_expr.cast_type->kind == AST_TYPE_F32);

  p = (Parser){0};
  p.tokens = get_tokens("(f32)1+1");
  e = parse_stmt(&p);
  mu_check(e->kind == AST_CAST);
  mu_check(e->value.cast_expr.expression->kind == AST_BINARY);
  mu_check(e->value.cast_expr.cast_type->kind == AST_TYPE_F32);
}


MU_TEST_SUITE(test_suite_parser) {
  MU_RUN_TEST(test_decl);
  MU_RUN_TEST(test_decl_struct);
  MU_RUN_TEST(test_decl_struct_ptr);
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

  MU_RUN_TEST(test_program_package);

  MU_RUN_TEST(test_struct);
  MU_RUN_TEST(test_function_decl);
  MU_RUN_TEST(test_function);
  MU_RUN_TEST(test_extern_function_decl);
  
  MU_RUN_TEST(test_call);
  MU_RUN_TEST(test_member_access);
  MU_RUN_TEST(test_member_access2);
  MU_RUN_TEST(test_cast);

  MU_RUN_TEST(test_visibility_decl);

  MU_RUN_TEST(test_unary);

  MU_RUN_TEST(test_index);

  MU_RUN_TEST(test_bool_literal);
  MU_RUN_TEST(test_char_literal);

  MU_RUN_TEST(test_if);
}
