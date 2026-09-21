#include "symbol_table.h"
#include "../include/stb_ds.h"
#include "ast.h"
#include "utils.h"
#include "type_resolver.h"
#include <assert.h>
#include <string.h>

void print_depth(int depth);


Symbol *symbol_create(Ast *node) {
  Symbol *ns = malloc(sizeof(Symbol));
  ns->node = node;
  ns->type = NULL;
  ns->scope = NULL;
  ns->key = NULL;
  ns->visibility = VIS_PRIVATE;


  
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
    ns->kind = SYMBOL_TYPE;
    ns->key = strdup(node->value.struct_decl.name);
    ns->visibility = node->value.struct_decl.visibility;
    break;
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
  debug_log("CREATED A NEW SYMBOL %s\n", ast_kind_to_string(node->kind));
  return ns;
}


Symbol *symbol_define(SymbolTable *root, Ast *node) {
  Symbol *sym = symbol_create(node);
  if (sym == NULL) return NULL;

  // add scope to the ast nodes that have it
  SymbolTable *table;
  switch (node->kind) {
  case AST_BLOCK:
    table = symbol_table_block(root, &node->value.block_stmt);
    table->parent = root;
    sym->scope = table;
    break;
  case AST_FUNC_DECL:
    table = symbol_table_block(root, &node->value.function_decl.body->value.block_stmt);

    for (int i = 0; i < arrlen(node->value.function_decl.parameters); i++) {
      Symbol *sym = symbol_create(node->value.function_decl.parameters[i]);
      sym->kind = SYMBOL_PARAMETER;
      // we insert at the begning beacuse we want the
      // parameters at the bengning
      arrins(table->symbols,0, sym);
    }

    table->parent = root;
    sym->scope = table;
    break;
  default:
    break;
  }
    
  arrput(root->symbols, sym);
  return sym;
}

Symbol *symbol_lookup(SymbolTable *table, const char *key) {
  for(int i = 0; i < arrlen(table->symbols); i ++) {
    Symbol *sym = table->symbols[i];
    if (strcmp(sym->key, key) == 0 ){
      return sym;
    }
  }
  if (table->parent != NULL) {
    return symbol_lookup(table->parent, key);
  }

  return NULL;
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
  
  Symbol *sym = malloc(sizeof(Symbol));
  sym->scope = table;
  sym->node = NULL;
  sym->kind = SYMBOL_PACKAGE;
  sym->key = strdup(package->package.value);

  arrput(root->symbols, sym);
  return table;
}



void symbol_table_resolve_types(TypeResolver *resolver, SymbolTable *table) {
  assert(table != NULL);
  assert(table->symbols != NULL);
  for(int i = 0; i < arrlen(table->symbols); i ++) {
    printf("IN LOOP");
    Symbol *sym = table->symbols[i];
    
    
    if (sym->node != NULL) {
      Ast* node = sym->node;
      printf("---resolve node in table----\n");
      print_ast(node, 0);
      printf("-------\n");
      Type *type = get_type(resolver, node);
      assert(type != NULL);
      sym->type = type;
    } else {
      sym->type = NULL;
    }
    if (sym->scope != NULL) {
      // FIXME MAYBE  reset the scope when done?
      resolver->scope = sym->scope;
      symbol_table_resolve_types(resolver, sym->scope);
    }
  }
  printf("AFTER LOOP\n");
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
  if (sym->type != NULL){
    printf("%s: ",type_kind_name(sym->type->kind));
  }
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
