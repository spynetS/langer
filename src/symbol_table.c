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


Symbol *symbol_define(SymbolTable *root, Symbol *sym) {
  //Symbol *sym = symbol_create(node);
  if (sym == NULL) return NULL;

  Ast *node = sym->node;

  // add scope to the ast nodes that have it
  SymbolTable *table;
  switch (node->kind) {
  case AST_BLOCK:
    table = symbol_table_block(root, &node->value.block_stmt);
    table->parent = root;
    sym->scope = table;
    break;
  case AST_FUNC_DECL:
    if (node->value.function_decl.body == NULL) {
      break;
    }
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
// ai
Symbol *symbol_lookup_path(SymbolTable *table_, MemberAccessExpr memexpr) {

  // If left is member we should 
  if (memexpr.left->kind == AST_MEMBER) {
    Symbol *parent = symbol_lookup_path(table_, memexpr.left->value.member_expr);

    if (parent == NULL)
      return NULL;

    if (parent->scope == NULL)
      return NULL;

    return symbol_lookup(parent->scope, memexpr.member);
        
  } else if (memexpr.left->kind == AST_IDENTIFER) {
    debug_log("Member was identifer '%s', look for symbol\n", memexpr.left->value.identifer_expr.value);
    Symbol *parent =
        symbol_lookup(table_, memexpr.left->value.identifer_expr.value);

    if (parent == NULL)
      return NULL;

    if (parent->scope == NULL) return parent;

    Symbol *sym = symbol_lookup(parent->scope, memexpr.member);
    print_symbol(sym, 0);
    return sym;
  }

  return NULL;
}

//ai
Symbol *symbol_lookup_path_str(SymbolTable *table, const char *name) {
    char *path = strdup(name);
    if (path == NULL)
        return NULL;

    char *token = strtok(path, ".");
    Symbol *sym = NULL;
    SymbolTable *scope = table;

    while (token != NULL) {
        sym = symbol_lookup(scope, token);

        if (sym == NULL) {
            free(path);
            return NULL;
        }

        token = strtok(NULL, ".");

        if (token != NULL) {
            if (sym->scope == NULL) {
                free(path);
                return NULL;
            }

            scope = sym->scope;
        }
    }

    free(path);
    return sym;
}


Symbol *symbol_lookup(SymbolTable *table, const char *key) {
  for(int i = 0; i < arrlen(table->symbols); i ++) {
    Symbol *sym = table->symbols[i];
    if (strcmp(sym->key, key) == 0) {
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
    symbol_define(table, symbol_create(blockstmt->stmts[i]));      
  }
  return table;
}

SymbolTable *symbol_table_package(
    SymbolTable *root,
    Package *package,
    const char *name
) {
    char *copy = strdup(name);
    if (!copy) return NULL;

    SymbolTable *parent = root;
    SymbolTable *table = NULL;

    char *saveptr;
    char *token = strtok_r(copy, ".", &saveptr);

    while (token != NULL) {
        // Check whether this package already exists in this scope.
        Symbol *sym = symbol_lookup(parent, token);

        if (sym != NULL) {
            if (sym->kind != SYMBOL_PACKAGE || sym->scope == NULL) {
                free(copy);
                return NULL; // Name already exists but isn't a package.
            }

            // Reuse the existing package's scope.
            table = sym->scope;
        } else {
            // Create a new package scope.
            table = calloc(1, sizeof(SymbolTable));
            if (!table) {
                free(copy);
                return NULL;
            }

            table->parent = parent;

            sym = calloc(1, sizeof(Symbol));
            if (!sym) {
                free(table);
                free(copy);
                return NULL;
            }

            sym->scope = table;
            table->owner = sym;
            sym->kind = SYMBOL_PACKAGE;
            sym->key = strdup(token);

            if (!sym->key) {
                free(sym);
                free(table);
                free(copy);
                return NULL;
            }

            arrput(parent->symbols, sym);
        }

        parent = table;
        token = strtok_r(NULL, ".", &saveptr);
    }

    free(copy);

    if (!table) return NULL;

    for (int i = 0; i < arrlen(package->declarations); i++) {
      symbol_define(table, symbol_create(package->declarations[i]));
    }

    return table;
}



void symbol_table_resolve_types(TypeResolver *resolver, SymbolTable *table) {
  assert(table != NULL);


  for(int i = 0; i < arrlen(table->symbols); i ++) {
    debug_log("IN LOOP\n");
    Symbol *sym = table->symbols[i];
    
    if (sym->node != NULL) {
      Ast* node = sym->node;
      debug_log("---resolve node in table----\n");
      print_ast(node, 0);
      debug_log("-------\n");
      Type *type = resolve_type(resolver, node);
      
      assert(type != NULL);
      sym->type = type;
    } else {
      sym->type = NULL;
    }
    if (sym->scope != NULL) {
      SymbolTable *old = resolver->scope;
      resolver->scope = sym->scope;
      symbol_table_resolve_types(resolver, sym->scope);
      resolver->scope = old;
    }
  }
  debug_log("AFTER LOOP\n");
}

void print_symbol(Symbol *sym, int depth)
{
  if (!sym) {
    debug_log("<null symbol>\n");
    return;
  }
  print_depth(depth);
  debug_log("Symbol {\n");
  print_depth(depth);
  debug_log("  visi: %s\n", sym->visibility == VIS_PRIVATE ? "private" : "public");
  print_depth(depth);
  debug_log("  name: %s\n", sym->key);
  print_depth(depth);
  debug_log("  kind: %s\n", symbol_kind_name(sym->kind));
  print_depth(depth);
  debug_log("  type: ");
  if (sym->type != NULL) {
    //debug_log("ASD: ");
    debug_log("%s: ",type_kind_name(sym->type->kind));
  }
  else
    debug_log("<none>");
  debug_log("\n");
  if (sym->scope) {

    print_depth(depth + 1);
    debug_log(" scope:\n");
    print_symbol_table(sym->scope, depth + 3);
  }
  debug_log("\n");
  print_depth(depth);
  debug_log("}\n");
}
  
void print_symbol_table(SymbolTable *scope, int depth)
{
  if (scope == NULL)
    return;

  print_depth(depth);
  debug_log("SymbolTable {\n");

  for (size_t i = 0; i < arrlen(scope->symbols); i++) {
    Symbol *sym = scope->symbols[i];
    print_symbol(sym, depth + 1);
  }

  print_depth(depth);
  debug_log("}\n");
}
