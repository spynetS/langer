#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include "type.h"
#include "ast.h"
#include <stdio.h>
#include <stdbool.h>


typedef enum {
    SYMBOL_VARIABLE,
    SYMBOL_FUNCTION,
    SYMBOL_TYPE,
    SYMBOL_PARAMETER,
    SYMBOL_FIELD,
} SymbolKind;


typedef struct {
  SymbolKind kind;
  const char *key;
  Type *type;
  Ast *node;
} Symbol;

// can be seen as the scope
typedef struct symbol_table {
  struct symbol_table *parent;
  Symbol **symbols; //stb dynamic array
  
} SymbolTable; 

Symbol *symbol_define(SymbolTable *table, Ast *node, const char* key);

Symbol *symbol_lookup(SymbolTable *table, const char *key);

void print_symbol(Symbol *sym);


#endif
