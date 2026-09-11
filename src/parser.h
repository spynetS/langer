#ifndef PARSER_H
#define PARSER_H

#include "./ast.h"
#include "./lexer.h"
#include <stdio.h>

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

Token parser_skip(Parser*, TokenKind);

Expr *parse_primary(Parser*);
Expr *parse_postfix(Parser*);
Expr *parse_term(Parser*);
Expr *parse_additive(Parser*);
Expr *parse_condition(Parser*);
Expr *parse_and(Parser*);
Expr *parse_or(Parser*);
Expr *parse_assignment(Parser*);
Expr *parse_expression(Parser*);




#endif
