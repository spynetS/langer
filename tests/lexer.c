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
  lexer.bytes = "+ - * / & && || = == % < > <= >= !=";
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
  mu_check(tokens[10].kind == TOKEN_LESS);
  mu_check(tokens[11].kind == TOKEN_GREATER);
  mu_check(tokens[12].kind == TOKEN_LE);
  mu_check(tokens[13].kind == TOKEN_GE);
  mu_check(tokens[14].kind == TOKEN_NOTEQUAL);
}

MU_TEST(test_comments) {

  Lexer lexer = {0};
  lexer.bytes = "// asdjh !a kjhowa int bla 123123 / asdw\n /* adlkalskjd */";
  lexer.bytes_length = strlen(lexer.bytes);

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);
  mu_check(arrlen(tokens) == 0);
}


MU_TEST(test_types) {

  Lexer lexer = {0};
  lexer.bytes = "char byte i16 int i32 i64 float f32 f64 double void bool";
  lexer.bytes_length = strlen(lexer.bytes);

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);
  mu_check(tokens[0].kind == TOKEN_BYTE);
  mu_check(tokens[1].kind == TOKEN_BYTE);
  mu_check(tokens[2].kind == TOKEN_I16);
  mu_check(tokens[3].kind == TOKEN_I32);
  mu_check(tokens[4].kind == TOKEN_I32);
  mu_check(tokens[5].kind == TOKEN_I64);
  mu_check(tokens[6].kind == TOKEN_F32);
  mu_check(tokens[7].kind == TOKEN_F32);
  mu_check(tokens[8].kind == TOKEN_F64);
  mu_check(tokens[9].kind == TOKEN_F64);
  mu_check(tokens[10].kind == TOKEN_VOID);
  mu_check(tokens[11].kind == TOKEN_BOOL);
}


MU_TEST(test_person_program) {

  Lexer lexer = {0};
  lexer.bytes =
    "package main;\n"
    "\n"
    "import std.fmt.println;\n"
    "import std.mem.*;\n"
    "\n"
    "public struct Person {\n"
    "\tpublic age: int;\n"
    "\tprivate name: string;\n"
    "}\n"
    "\n"
    "public func new(): *Person {\n"
    "\tperson : *Person = malloc(sizeof(Person));\n"
    "\tperson.age = 22;\n"
    "\tperson.name = \"Alfred\";\n"
    "\treturn person;\n"
    "}\n"
    "\n"
    "func main(): int {\n"
    "\t// this is init\n"
    "\talfred := new();\n"
    "\t//printing\n"
    "\tprintln(\"Hello World!, Im {}\", alfred.name);\n"
    "\t/* Then we change the body of it */\n"
    "\talfred* = (Person){67, \"billy\"}\n"
    "\tprintln(\"Hello World!, Im {}\", alfred.name);\n"
    "\n"
    "\treturn 0;\n"
    "}\n";

  lexer.bytes_length = strlen(lexer.bytes);

  Token *tokens = NULL;
  lexer_tokenize(&lexer, &tokens);

  int i = 0;

  /* package main; */
  mu_check(tokens[i++].kind == TOKEN_PACKAGE);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* import std.fmt.println; */
  mu_check(tokens[i++].kind == TOKEN_IMPORT);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);   // std
  mu_check(tokens[i++].kind == TOKEN_DOT);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);   // fmt
  mu_check(tokens[i++].kind == TOKEN_DOT);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);   // println
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* import std.mem.*; */
  mu_check(tokens[i++].kind == TOKEN_IMPORT);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);   // std
  mu_check(tokens[i++].kind == TOKEN_DOT);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);   // mem
  mu_check(tokens[i++].kind == TOKEN_DOT);
  mu_check(tokens[i++].kind == TOKEN_STAR);
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* public struct Person { */
  mu_check(tokens[i++].kind == TOKEN_PUBLIC);
  mu_check(tokens[i++].kind == TOKEN_STRUCT);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_LCBRACK);

  /* public age: int; */
  mu_check(tokens[i++].kind == TOKEN_PUBLIC);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_COLON);
  mu_check(tokens[i++].kind == TOKEN_I32);
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* private name: string; */
  mu_check(tokens[i++].kind == TOKEN_PRIVATE);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_COLON);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);  // string
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* } */
  mu_check(tokens[i++].kind == TOKEN_RCBRACK);

  /* public func new(): *Person { */
  mu_check(tokens[i++].kind == TOKEN_PUBLIC);
  mu_check(tokens[i++].kind == TOKEN_FUNC);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);  // new
  mu_check(tokens[i++].kind == TOKEN_LPAR);
  mu_check(tokens[i++].kind == TOKEN_RPAR);
  mu_check(tokens[i++].kind == TOKEN_COLON);
  mu_check(tokens[i++].kind == TOKEN_STAR);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);  // Person
  mu_check(tokens[i++].kind == TOKEN_LCBRACK);

  /* person : *Person = malloc(sizeof(Person)); */
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);  // person
  mu_check(tokens[i++].kind == TOKEN_COLON);
  mu_check(tokens[i++].kind == TOKEN_STAR);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);  // Person
  mu_check(tokens[i++].kind == TOKEN_ASSIGN);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);  // malloc
  mu_check(tokens[i++].kind == TOKEN_LPAR);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);  // sizeof
  mu_check(tokens[i++].kind == TOKEN_LPAR);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);  // Person
  mu_check(tokens[i++].kind == TOKEN_RPAR);
  mu_check(tokens[i++].kind == TOKEN_RPAR);
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* person.age = 22; */
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_DOT);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_ASSIGN);
  mu_check(tokens[i++].kind == TOKEN_INTEGER_LITERAL);
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* person.name = "Alfred"; */
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_DOT);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_ASSIGN);
  mu_check(tokens[i++].kind == TOKEN_STRING_LITERAL);
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* return person; */
  mu_check(tokens[i++].kind == TOKEN_RETURN);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* } */
  mu_check(tokens[i++].kind == TOKEN_RCBRACK);

  /* func main(): int { */
  mu_check(tokens[i++].kind == TOKEN_FUNC);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_LPAR);
  mu_check(tokens[i++].kind == TOKEN_RPAR);
  mu_check(tokens[i++].kind == TOKEN_COLON);
  mu_check(tokens[i++].kind == TOKEN_I32);
  mu_check(tokens[i++].kind == TOKEN_LCBRACK);

  /* alfred := new(); */
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_COLON);
  mu_check(tokens[i++].kind == TOKEN_ASSIGN);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_LPAR);
  mu_check(tokens[i++].kind == TOKEN_RPAR);
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* println("Hello World!, Im {}", alfred.name); */
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_LPAR);
  mu_check(tokens[i++].kind == TOKEN_STRING_LITERAL);
  mu_check(tokens[i++].kind == TOKEN_COMMA);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_DOT);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_RPAR);
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* alfred* = (Person){67, "billy"} */
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_STAR);
  mu_check(tokens[i++].kind == TOKEN_ASSIGN);
  mu_check(tokens[i++].kind == TOKEN_LPAR);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_RPAR);
  mu_check(tokens[i++].kind == TOKEN_LCBRACK);
  mu_check(tokens[i++].kind == TOKEN_INTEGER_LITERAL);
  mu_check(tokens[i++].kind == TOKEN_COMMA);
  mu_check(tokens[i++].kind == TOKEN_STRING_LITERAL);
  mu_check(tokens[i++].kind == TOKEN_RCBRACK);

  /* println("Hello World!, Im {}", alfred.name); */
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_LPAR);
  mu_check(tokens[i++].kind == TOKEN_STRING_LITERAL);
  mu_check(tokens[i++].kind == TOKEN_COMMA);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_DOT);
  mu_check(tokens[i++].kind == TOKEN_IDENTIFER);
  mu_check(tokens[i++].kind == TOKEN_RPAR);
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* return 0; */
  mu_check(tokens[i++].kind == TOKEN_RETURN);
  mu_check(tokens[i++].kind == TOKEN_INTEGER_LITERAL);
  mu_check(tokens[i++].kind == TOKEN_SEMICOLON);

  /* } */
  mu_check(tokens[i++].kind == TOKEN_RCBRACK);

  /* EOF */
  //mu_check(tokens[i].kind == TOKEN_EOF);
}

MU_TEST_SUITE(test_suite) {
	MU_RUN_TEST(test_a);
	MU_RUN_TEST(test_string_literal);
  MU_RUN_TEST(test_wrong_string_literal);
  MU_RUN_TEST(test_keywords);
  MU_RUN_TEST(test_numbers);
  MU_RUN_TEST(test_chars);
  MU_RUN_TEST(test_operators);
  MU_RUN_TEST(test_comments);
  MU_RUN_TEST(test_types);
  MU_RUN_TEST(test_person_program);
}



int main(int argc, char *argv[]) {
	MU_RUN_SUITE(test_suite);
	MU_REPORT();
	return MU_EXIT_CODE;
}
