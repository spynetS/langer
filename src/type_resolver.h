#ifndef TYPE_RESOLVER_H
#define TYPE_RESOLVER_H

#include "type.h"
#include "symbol_table.h"
#include "ast.h"
#include <stdbool.h>

typedef struct type_resolver {
  struct symbol_table *scope;
  bool resolve_expr;
} TypeResolver;

Type *get_type(TypeResolver*, Ast*);

void type_check_package(TypeResolver *resolver, Package *package);

#endif
