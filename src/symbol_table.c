#include "symbol_table.h"
#include "ast.h"
#include "utils.h"
#include <stdlib.h>
#include <string.h>

void print_symbol(Symbol *sym)
{
    if (!sym) {
        printf("<null symbol>\n");
        return;
    }

    printf("Symbol {\n");
    printf("  name: %s\n", sym->key);
    printf("  kind: %s\n", symbol_kind_name(sym->kind));

    printf("  type: ");
    if (sym->type)
      printf("%s: ",type_kind_name(sym->type->kind));
    else
        printf("<none>");

    printf("\n}\n");
}

Type *symbol_get_type(Ast *node) {
  
}

Symbol *symbol_create(Ast *node, const char* key) {
  Symbol *ns = malloc(sizeof(Symbol));
  ns->key = strdup(key);
  ns->node = node;
  ns->type = NULL;

  switch (node->kind) {
  case AST_VAR_DECL:
    ns->kind = SYMBOL_VARIABLE;
    break;
  case AST_FUNC_DECL:
    ns->kind = SYMBOL_FUNCTION;
    break;
  case AST_STRUCT_DECL:
  case AST_ENUM_DECL:
  case AST_UNION_DECL:
    ns->kind = SYMBOL_TYPE;
    break;
  case AST_MEMBER:
    ns->kind = SYMBOL_FIELD;
    break;
  default:
    break;
  }
  printf("CREATED A NEW SYMBOL %s\n", ast_kind_to_string(node->kind));
  return ns;
}


Symbol *symbol_define(SymbolTable *table, Ast *node, const char* key) {

  Symbol *sym = symbol_create(node, key);

  return sym;
}
