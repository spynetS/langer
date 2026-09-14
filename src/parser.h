#ifndef PARSER_H
#define PARSER_H

#include "./ast.h"
#include "./lexer.h"
#include <stdio.h>
#include <stdbool.h>

/*


  This should be an
  predictive Recursive descent parser

  example syntax

package main;

import std.fmt.println;
import std.mem.*;

public struct Person {
	public age: int;
	private name: string;
}

public func new(): *Person {
	person : *Person = malloc(sizeof(Person));
	person.age = 22;
	person.name = "Alfred";
	return person;
}


func main(): int {

	alfred := new();

	println("Hello World!, Im {}", alfred.name);
	*alfred = (Person){67, "billy"}
	println("Hello World!, Im {}", alfred.name);


	return 0;
}

 */

typedef struct {
  size_t pos;
  Token *tokens; // stb_arr
} Parser;

Token parser_skip(Parser *, TokenKind);
// Returns true if next is tokenkind
// if it is it will advance the parser
bool parser_is(Parser*, TokenKind);

Ast *parse_primary(Parser*);
Ast *parse_postfix(Parser*);
Ast *parse_term(Parser*);
Ast *parse_additive(Parser*);
Ast *parse_condition(Parser*);
Ast *parse_and(Parser*);
Ast *parse_or(Parser*);
Ast *parse_assignment(Parser*);
Ast *parse_expression(Parser*);

Ast *parse_stmt(Parser*);
Ast *parse_block(Parser*);
Ast *parse_function(Parser*);
Ast *parse_struct_decl(Parser *p);

Ast *parse_package(Parser *p);
Ast *parse_variable_decl(Parser *p);
  
Program *parse_program(Parser *p);

#endif
