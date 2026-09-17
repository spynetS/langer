#include "symbol_table.h"
#include "../include/stb_ds.h"
#include "ast.h"
#include "utils.h"
#include <assert.h>
#include <string.h>

void print_depth(int depth);

Type *symbol_get_type(AstKind kind) {
  Type *type = malloc(sizeof(Type));
  switch(kind) {
  case AST_VAR_DECL:
    type->kind = TYPE_I16;
  case AST_TYPE_I32:
    type->kind = TYPE_I32;
  case AST_TYPE_I64:
    type->kind = TYPE_I64;
  case AST_TYPE_F32:
    type->kind = TYPE_F32;
  case AST_TYPE_F64:
    type->kind = TYPE_F64;
  }
  return NULL;
}

Symbol *symbol_create(Ast *node) {
  Symbol *ns = malloc(sizeof(Symbol));
  ns->node = node;

  switch (node->kind) {
  case AST_VAR_DECL:
    ns->kind = SYMBOL_VARIABLE;
    ns->key =
      strdup(node->value.variable_decl.left->value.identifer_expr.value);
    ns->visibility = node->value.variable_decl.visibility;
    break;
  case AST_FUNC_DECL:
    ns->kind = SYMBOL_FUNCTION;
    ns->key = strdup(node->value.function_decl.name);
    ns->visibility = node->value.function_decl.visibility;
    break;
  case AST_BLOCK:
    ns->kind = SYMBOL_BLOCK;
    ns->key = "<block with no name>";
    break;
  case AST_STRUCT_DECL:
    ns->key = strdup(node->value.struct_decl.name);
    ns->visibility = node->value.struct_decl.visibility;
  case AST_ENUM_DECL:
  case AST_UNION_DECL:
    ns->kind = SYMBOL_TYPE;
    break;
  case AST_MEMBER:
    ns->kind = SYMBOL_FIELD;
    break;
  default:
    free(ns);
    return NULL;
    break;
  }
  printf("CREATED A NEW SYMBOL %s\n", ast_kind_to_string(node->kind));
  return ns;
}


Symbol *symbol_define(SymbolTable *root, Ast *node) {
  Symbol *sym = symbol_create(node);
  if (sym == NULL) return NULL;

  SymbolTable *table;
  
  switch (node->kind) {
  case AST_BLOCK:
    table = symbol_table_block(root, &node->value.block_stmt);
    table->parent = root;
    sym->scope = table;
    break;
  case AST_FUNC_DECL:
    table = symbol_table_block(root, &node->value.function_decl.body->value.block_stmt);
    table->parent = root;
    sym->scope = table;
    break;
  default:
    break;
  }
    
  arrput(root->symbols, sym);
  return sym;
}


SymbolTable *symbol_table_block(SymbolTable *root, BlockStmt *blockstmt) {
  SymbolTable *table = malloc(sizeof(SymbolTable));
  table->symbols = NULL;
  table->parent = root;
  for (int i = 0; i < arrlen(blockstmt->stmts); i++) {
    //    print_ast( blockstmt->stmts[i], 0);
    Symbol *sym = symbol_define(table, blockstmt->stmts[i]);
  }
  return table;
}


SymbolTable *symbol_table_package(SymbolTable *root, Package *package) {
  SymbolTable *table = malloc(sizeof(SymbolTable));
  table->symbols = NULL;
  table->parent = root;
  for (int i = 0; i < arrlen(package->declarations); i++) {
    Symbol *sym = symbol_define(table, package->declarations[i]);
  }
  print_symbol_table(table, 0);
  return table;
}



void print_symbol(Symbol *sym, int depth)
{
    if (!sym) {
        printf("<null symbol>\n");
        return;
    }
    print_depth(depth);
    printf("Symbol {\n");
    print_depth(depth);
    printf("  visi: %s\n", sym->visibility == VIS_PRIVATE ? "private" : "public");
    print_depth(depth);
    printf("  name: %s\n", sym->key);
    print_depth(depth);
    printf("  kind: %s\n", symbol_kind_name(sym->kind));
    print_depth(depth);
    printf("  type: ");
    if (sym->type)
      printf("%s: ",type_kind_name(sym->type->kind));
    else
      printf("<none>");
    printf("\n");
    if (sym->scope) {
      print_depth(depth + 1);
      printf(" scope:\n");
      print_symbol_table(sym->scope, depth + 3);
    }
    printf("\n");
    print_depth(depth);
    printf("}\n");
}

void print_symbol_table(SymbolTable *scope, int depth)
{
    if (scope == NULL)
        return;

    print_depth(depth);
    printf("SymbolTable {\n");

    for (size_t i = 0; i < arrlen(scope->symbols); i++) {
        Symbol *sym = scope->symbols[i];

        print_symbol(sym, depth + 1);
    }

    print_depth(depth);
    printf("}\n");
}
