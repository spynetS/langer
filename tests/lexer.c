#include "minunit.h"
#include "../src/lexer.h"
#include <string.h>
#include <stdio.h>
#define STB_DS_IMPLEMENTATION
#include "../src/stb_ds.h"



MU_TEST(test_a) {
  Lexer lexer = {0};
  lexer.bytes = "asd asd_ asd1 asd_1";
  lexer.bytes_length = strlen(lexer.bytes);

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);
  mu_check(tokens[0].kind == TOKEN_IDENTIFER);
  mu_check(tokens[1].kind == TOKEN_IDENTIFER);
  mu_check(tokens[2].kind == TOKEN_IDENTIFER);
  mu_check(tokens[3].kind == TOKEN_IDENTIFER);
}


MU_TEST(test_string_literal) {
  Lexer lexer = {0};
  lexer.bytes = "\"asd123_asd3123!\"";
  lexer.bytes_length = strlen(lexer.bytes);
  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);
  mu_check(arrlen(tokens) > 0);
  mu_check(tokens[0].kind == TOKEN_STRING_LITERAL);
}


MU_TEST(test_wrong_string_literal) {

  Lexer lexer = {0};
  lexer.bytes = "\"asd123_asd3123!";
  lexer.bytes_length = strlen(lexer.bytes);

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);
  mu_check(arrlen(tokens) == 0);
}


MU_TEST(test_keywords)
{
    Lexer lexer = {0};
    lexer.bytes = "if else while return func struct i32 f64 true false";
    lexer.bytes_length = strlen(lexer.bytes);

    Token *tokens = NULL;
    lexer_tokenize(&lexer, &tokens);

    mu_check(arrlen(tokens) == 10);

    mu_check(tokens[0].kind == TOKEN_IF);
    mu_check(tokens[1].kind == TOKEN_ELSE);
    mu_check(tokens[2].kind == TOKEN_WHILE);
    mu_check(tokens[3].kind == TOKEN_RETURN);
    mu_check(tokens[4].kind == TOKEN_FUNC);
    mu_check(tokens[5].kind == TOKEN_STRUCT);
    mu_check(tokens[6].kind == TOKEN_I32);
    mu_check(tokens[7].kind == TOKEN_F64);
    mu_check(tokens[8].kind == TOKEN_TRUE);
    mu_check(tokens[9].kind == TOKEN_FALSE);

    arrfree(tokens);
}


MU_TEST(test_numbers) {

  Lexer lexer = {0};
  lexer.bytes = "100 0 1 1.0 0.1";
  lexer.bytes_length = strlen(lexer.bytes);

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);
  mu_check(tokens[0].kind == TOKEN_INTEGER_LITERAL);
  mu_check(tokens[1].kind == TOKEN_INTEGER_LITERAL);
  mu_check(tokens[2].kind == TOKEN_INTEGER_LITERAL);
  mu_check(tokens[3].kind == TOKEN_FLOAT_LITERAL);
  mu_check(tokens[4].kind == TOKEN_FLOAT_LITERAL);
}

MU_TEST(test_chars) {

  Lexer lexer = {0};
  lexer.bytes = "'a' '1' '!' ' ' '\''";
  lexer.bytes_length = strlen(lexer.bytes);

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);
  mu_check(tokens[0].kind == TOKEN_CHAR_LITERAL);
  mu_check(tokens[1].kind == TOKEN_CHAR_LITERAL);
  mu_check(tokens[2].kind == TOKEN_CHAR_LITERAL);
  mu_check(tokens[3].kind == TOKEN_CHAR_LITERAL);
  mu_check(tokens[4].kind == TOKEN_CHAR_LITERAL);
}

MU_TEST(test_operators) {

  Lexer lexer = {0};
  lexer.bytes = "+ - * / & && || = == %";
  lexer.bytes_length = strlen(lexer.bytes);

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);
  mu_check(tokens[0].kind == TOKEN_PLUS);
  mu_check(tokens[1].kind == TOKEN_MINUS);
  mu_check(tokens[2].kind == TOKEN_STAR);
  mu_check(tokens[3].kind == TOKEN_SLASH);
  mu_check(tokens[4].kind == TOKEN_AMPER);
  mu_check(tokens[5].kind == TOKEN_AND);
  mu_check(tokens[6].kind == TOKEN_OR);
  mu_check(tokens[7].kind == TOKEN_ASSIGN);
  mu_check(tokens[8].kind == TOKEN_EQUAL);
  mu_check(tokens[9].kind == TOKEN_MOD);
}



MU_TEST_SUITE(test_suite) {
	MU_RUN_TEST(test_a);
	MU_RUN_TEST(test_string_literal);
  MU_RUN_TEST(test_wrong_string_literal);
  MU_RUN_TEST(test_keywords);
  MU_RUN_TEST(test_numbers);
  MU_RUN_TEST(test_chars);
  MU_RUN_TEST(test_operators);
}

int main(int argc, char *argv[]) {
	MU_RUN_SUITE(test_suite);
	MU_REPORT();
	return MU_EXIT_CODE;
}
