#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include "type.h"
#include "ast.h"
#include "type_resolver.h"
#include <stdio.h>
#include <stdbool.h>


typedef enum {
    SYMBOL_VARIABLE,
    SYMBOL_FUNCTION,
    SYMBOL_PACKAGE,
    SYMBOL_BLOCK,
    SYMBOL_TYPE,
    SYMBOL_PARAMETER,
    SYMBOL_FIELD,
} SymbolKind;

typedef struct symbol_table SymbolTable;

typedef struct {
  SymbolKind kind;
  const char *key;
  Type *type;
  Ast *node;
  Visibility visibility;

  SymbolTable *scope;
} Symbol;

// can be seen as the scope
typedef struct symbol_table {
  struct symbol_table *parent;
  Symbol **symbols; //stb dynamic array
} SymbolTable; 



Symbol *symbol_define(SymbolTable *table, Ast *node);
Symbol *symbol_lookup(SymbolTable *table, const char *key);

SymbolTable *symbol_table_block(SymbolTable *root, BlockStmt *blockstmt);
SymbolTable *symbol_table_package(SymbolTable *root, Package *package);

void symbol_table_resolve_types(struct type_resolver *resolver, SymbolTable *table);

void print_symbol(Symbol *sym, int depth);
void print_symbol_table(SymbolTable *scope, int depth);
  
#endif
