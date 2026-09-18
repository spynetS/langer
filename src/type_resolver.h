#ifndef TYPE_RESOLVER_H
#define TYPE_RESOLVER_H

#include "type.h"
#include "symbol_table.h"
#include "ast.h"

typedef struct type_resolver {
  struct symbol_table *scope;
} TypeResolver;

Type *get_type(TypeResolver*, Ast*);

#endif
