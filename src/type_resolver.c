#include "type_resolver.h"
#include "ast.h"
#include "symbol_table.h"
#include "type.h"
#include "utils.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "../include/stb_ds.h"

// implemented in parser.c
Ast *new_ast(AstKind kind, SourceSpan span);
Type *common_type(Type *a, Type *b);
Ast* implicit_cast(Ast* node, Type* t);

Type *new_type(TypeKind kind) {
  Type *type = malloc(sizeof(Type));
  type->kind = kind;
  return type;
}

Type *convert_type(TypeResolver *resolver, Ast* atype) {
  Type *type = malloc(sizeof(Type));
  switch(atype->kind) {
  case AST_TYPE_BOOL:
    type->kind = TYPE_BOOL;
    break;
  case AST_TYPE_VOID:
    type->kind = TYPE_VOID;
    break;
  case AST_TYPE_POINTER:
    type->kind = TYPE_POINTER;
    type->Pointer.base = convert_type(resolver, atype->value.pointer_type.to);
    break;
  case AST_TYPE_BYTE:
    type->kind = TYPE_BYTE;
    break;
  case AST_TYPE_I16:
    type->kind = TYPE_I16;
    break;
  case AST_TYPE_I32:
    type->kind = TYPE_I32;
    break;
  case AST_TYPE_I64:
    type->kind = TYPE_I64;
    break;
  case AST_TYPE_F32:
    type->kind = TYPE_F32;
    break;
  case AST_TYPE_F64:
    type->kind = TYPE_F64;
    break;
  case AST_TYPE_NAME:
    if (resolver == NULL) return new_type(TYPE_RESOLVING);
    // the ast node is a type
    Ast *name = atype->value.named_type.name;
    Symbol *sym = NULL;
    if (name->kind == AST_IDENTIFER) {
      debug_log("IDENTIFER \n");
      sym = symbol_lookup(resolver->scope, name->value.identifer_expr.value);
    } else {
      print_ast(name, 0);
      sym = symbol_lookup_path(resolver->scope, name->value.member_expr);
    }
    if (sym == NULL) {
      log_span(name->span, "error: symbol 'TODO' could not be found \n");
      assert(false);
    } else if (sym->type == NULL) {
      // if its type is null we resolve it
      sym->type = resolve_type(resolver, sym->node);
    }
    assert(sym->type != NULL);
    return sym->type;
    break;
  default:
    assert(0);
    break;
  }
  return type;
}

Type *resolve_var_decl(TypeResolver *resolver, Ast *node) {
  Type *type = NULL;
  if (node->value.variable_decl.initlizer != NULL) {
    type = resolve_type(resolver, node->value.variable_decl.initlizer);
    assert(type != NULL);
  }
  if (node->value.variable_decl.type != NULL ) {
    type =  convert_type(resolver, node->value.variable_decl.type);
      assert(type != NULL);
  }
    assert(type != NULL);
  node->type = type;
  return type;
}

Type *resolve_struct_decl (TypeResolver *resolver, Ast *node) {
  StructDecl decl = node->value.struct_decl;
  
  Type *type = new_type(TYPE_STRUCT);
  type->Struct.name = decl.name;
  type->Struct.members = NULL;
  node->type = type;

  for (int i = 0; i < arrlen(decl.members); i++) {
    Member m = {0};
    m.name = strdup(
                    decl.members[i]->value.variable_decl.left->value.identifer_expr.value);
    m.type = resolve_type(resolver, decl.members[i]);
    arrput(type->Struct.members, m);
  }

  return type;
}

Type *resolve_call(TypeResolver *resolver, Ast *node) {
  assert(node->kind == AST_CALL);
  
  Symbol *sym = NULL;
  if(node->value.call_expr.left->kind == AST_MEMBER) {
    MemberAccessExpr path = node->value.call_expr.left->value.member_expr;
    sym = symbol_lookup_path(resolver->scope, path);
    if(sym == NULL) {
      log_span(node->value.call_expr.left->span, "error: Symbol '%s' not found\n", path.member);
      assert(false);
    }

  } else if (node->value.call_expr.left->kind == AST_IDENTIFER) {
    char* name = node->value.call_expr.left->value.identifer_expr.value;
    sym = symbol_lookup(resolver->scope, name);
    if(sym == NULL) {
      log_span(node->span, "error: Symbol '%s' not found\n", name);
      assert(false);
    }

  } else {
    log_span(node->span, "error: Something wrong with call expression\n");
    assert(false);
  }
  
  if (sym == NULL) {
    log_span(node->span, "error: Symbol not found\n");
    assert(0);
  }

  

  if (sym->type == NULL) {
    return new_type(TYPE_RESOLVING);
  }
    
  size_t pl = arrlen(node->value.call_expr.parameters);
  if(!sym->type->Function.is_variadic && arrlen(sym->type->Function.parameters) != pl) {
    log_span(node->span, "error: function call parameters length mismatch\n");
    assert(0);
  }

  for(size_t i = 0; i < pl; i ++){
    Type *a = resolve_type(resolver, node->value.call_expr.parameters[i]);
    Type *b = sym->type->Function.parameters[i];

    Type *common = common_type(a, b);
    if(common == NULL) {
      log_span(node->span, "error: Expected '%s' got '%s' \n", type_kind_name(b->kind), type_kind_name(a->kind));
      assert(0);
    }
  }

  Type* t = sym->type->Function.return_type;
  return t;
}


Type *resolve_member(TypeResolver *resolver, Ast *node) {
  assert(node->kind == AST_MEMBER);

  MemberAccessExpr expr = node->value.member_expr;

  Type *left_type = resolve_type(resolver, expr.left);

  if (left_type == NULL)
    return NULL;

  if (left_type->kind != TYPE_STRUCT) {
    log_span(node->span,
             "error: cannot access member '%s' on non-struct type\n",
             expr.member);
    return NULL;
  }

  for (size_t i = 0; i < arrlen(left_type->Struct.members); i++) {
    Member *member = &left_type->Struct.members[i];

    if (strcmp(member->name, expr.member) == 0)
      return member->type;
  }

  log_span(node->span,
           "error: struct has no member '%s'\n",
           expr.member);

  return NULL;
}

void resolve_block(TypeResolver *resolver, Ast *node, Type *return_type) {
  assert(node->kind == AST_BLOCK);

  if (!resolver->resolve_expr)
    return;
  BlockStmt block = node->value.block_stmt;
  for (int i = 0; i < arrlen(block.stmts); i++) {
    Type *type = resolve_type(resolver, block.stmts[i]);
    if (block.stmts[i]->kind == AST_RETURN && return_type != NULL) {
      if (return_type->kind != type->kind) {
        log_span(block.stmts[i]->value.return_stmt.value->span,
                 "error: wrong return type, expected '%s' got '%s'\n",
                 type_kind_name(return_type->kind),
                type_kind_name(type->kind));
        assert(0);
      }
    }
  }
}

void get_package_name(SymbolTable *scope, char *dst) {
  assert(scope != NULL);
  assert(scope->symbols != NULL);
  assert(scope->owner != NULL);

  SymbolTable *t = scope;
  snprintf(dst, 256, "%s", t->owner->key);
  t = t->parent;

  while(t != NULL && t->owner != NULL) {
    char tmp[256];
    snprintf(tmp, sizeof(tmp), "%s.%s", t->owner->key, dst);
    snprintf(dst, 256, "%s", tmp);
    t = t->parent;
  }
  
}

Type *resolve_func_decl (TypeResolver *resolver, Ast *node) {
  FunctionDecl decl = node->value.function_decl;
  debug_log("===resolving function decl %s\n", decl.name);
  
  Type *ftype = new_type(TYPE_FUNCTION);
  ftype->Function.return_type = convert_type(resolver, decl.return_type);
  ftype->Function.parameters = NULL;

  ftype->Function.name = malloc(256);

  if (decl.is_extern == false){
    // FIXME not hardcode?
    char name[516];
    debug_log("%s\n", decl.name);
    // if we resolve expretsions the resolve scope are inside the function
    // and therefore we need  to step back a step to retrive the package name
    // FIXME by making the get pcakage to this if necessary?
    SymbolTable *scope =  resolver->resolve_expr == false ? resolver->scope : resolver->scope->parent;
    get_package_name(scope, name);
    snprintf(ftype->Function.name, 516, "%s.%s", name, decl.name);
  } else {
    snprintf(ftype->Function.name, 516, "%s", decl.name);
  }
  debug_log("start parameters\n");
  
  for(int i = 0; i < arrlen(decl.parameters); i ++) {
    Type *type = resolve_type(resolver, decl.parameters[i]);
    assert(type != NULL);
    arrput(ftype->Function.parameters, type);
  }
  
  debug_log("end parameters\n");
  if (decl.body != NULL && resolver->resolve_expr == true) {
    Type *return_type = resolve_type(resolver, decl.return_type);
    assert(return_type != NULL);
    resolve_block(resolver, decl.body, return_type);
  }

  
  
  node->type = ftype;
  debug_log("====end resolving function decl %s\n", decl.name);
  return ftype;
}

bool is_numeric(Type *a) {
  switch(a->kind) {
  case TYPE_BYTE:
  case TYPE_I16:
  case TYPE_I32:
  case TYPE_I64:
  case TYPE_F32:
  case TYPE_F64:
    return true;
  default: return false;
  }
}

bool is_double(Type *a) {
  switch(a->kind) {
  case TYPE_F64:
    return true;
  default: return false;
  }
}

bool is_int(Type *a) {
  switch(a->kind) {
  case TYPE_BYTE:
  case TYPE_I16:
  case TYPE_I32:
  case TYPE_I64:
    return true;
  default: return false;
  }  
}

int integer_width(Type *type) {
    switch (type->kind) {
    case TYPE_BYTE:  return 8;
    case TYPE_I16: return 16;
    case TYPE_I32: return 32;
    case TYPE_I64: return 64;
    default:       return 0;
    }
}

Type *common_integer_type(Type *a, Type *b) {
    int wa = integer_width(a);
    int wb = integer_width(b);

    if (wa == 0 || wb == 0)
        return NULL;

    return wa >= wb ? a : b;
}

Type *common_type(Type *a, Type *b) {
  assert(a != NULL);
  assert(b != NULL);

  if (a->kind == b->kind) {
    return a;
  }

  if(is_numeric(a) && is_numeric(b)) {

    if (is_int(a) && is_int(b))
      return common_integer_type(a, b);

    if(a->kind == TYPE_F64 || b->kind == TYPE_F64) {
      return new_type(TYPE_F64);
    }
    if(a->kind == TYPE_F32 || b->kind == TYPE_F32) {
      return new_type(TYPE_F32);
    }
    assert(0 && "TODO");
  }
  else if ((a->kind == TYPE_POINTER && b->kind == TYPE_STRING )) return a;
  else if ((b->kind == TYPE_POINTER && a->kind == TYPE_STRING )) return b;
  else {
    return NULL;
  }
  
  return a;
}

Type *resolve_assign(TypeResolver *resolver, Ast *node) {
  assert(node->kind == AST_ASSIGN);

  Type *left_type = resolve_type(resolver, node->value.assign_expr.left);
  Type *value_type = resolve_type(resolver, node->value.assign_expr.value);  
  
  if (common_type(left_type, value_type) == NULL) {
    log_span(node->span, "error: Can't assign type '%s' to type '%s' \n",
             type_kind_name(left_type->kind),
            type_kind_name(value_type->kind));
    assert(0);
  }

  //node->value.assign_expr.value = implicit_cast(node->value.assign_expr.value, left_type); 
  node->value.assign_expr.value->type = left_type;
  node->type = left_type;

  return left_type;
}

Ast* implicit_cast(Ast* node, Type* t) {
  assert(node != NULL);
  // if it already is the type we dont need to do anything
  if(node->type != NULL && node->type->kind == t->kind) return node;
  
  Ast * new = new_ast(AST_CAST, node->span);
  new->value.cast_expr.expression = node;
  new->value.cast_expr.cast_type = t;
  new->type = t;
  return new;
}

Type *resolve_binary(TypeResolver *resolver, Ast *node) {
  debug_log("resolving binary\n");
  assert(node->kind == AST_BINARY);
  BinaryExpr *expr = &node->value.binary_expr;

  expr->left->type = resolve_type(resolver, expr->left);
  expr->right->type = resolve_type(resolver, expr->right);

  assert(expr->left->type != NULL);

  Type* type = common_type(expr->left->type, expr->right->type);

  if (type == NULL) {
    log_span(expr->left->span, "Cant cast\n");
    assert(0);
  }

  expr->left = implicit_cast(expr->left, type);
  expr->right = implicit_cast(expr->right, type);

  return type;
}
Type *resolve_identifer(TypeResolver *resolver, Ast *node) {
  assert(node->kind == AST_IDENTIFER);
  Symbol *sym = symbol_lookup(resolver->scope, node->value.identifer_expr.value);
  if (sym == NULL) {
    log_span(node->span, "error: Symbol not found\n");
    assert(0);
  }

  return sym->type;
}

bool can_cast(TypeResolver *resolver, Type* a, Type* b) {
  if (is_numeric(a) && is_numeric(b)) {
    return true;
  }
  return false;
}

Type *resolve_index(TypeResolver *resolver, Ast *node) {
  assert(node->kind == AST_INDEX);
  IndexExpr expr = node->value.index_expr;
  Type *lt = resolve_type(resolver, expr.left);
  assert(lt != NULL);

  Type *it = resolve_type(resolver, expr.index);
  assert(it != NULL);

  switch(lt->kind) {
  case TYPE_POINTER:
    assert(lt->Pointer.base != NULL);
    return lt->Pointer.base;
  case TYPE_ARRAY:
    assert(0 && "ARRAY");
  case TYPE_STRUCT:
    assert(0 && "STRUCT");
  default:
    assert(0 && "NOT IMPLEMENTED YET");
  }
  assert(0);
}
Type *resolve_cast(TypeResolver *resolver, Ast *node) {  
  assert(node->kind == AST_CAST);
  CastExpr expr = node->value.cast_expr;

  expr.expression->type = resolve_type(resolver, expr.expression);

  if (!can_cast(resolver, expr.cast_type, expr.expression->type)) {
    log_span(node->span,
             "error: can't cast '%s' to '%s'\n",
             type_kind_name(expr.expression->type->kind),
             type_kind_name(expr.cast_type->kind));
    assert(0);
  }

  return expr.cast_type;
}

Type *resolve_type(TypeResolver *resolver, Ast *node) {
  Type *type = NULL;

  switch(node->kind) {
  case AST_VAR_DECL:
    type = resolve_var_decl(resolver, node);
    break;
  case AST_FUNC_DECL:
    type = resolve_func_decl(resolver, node);
    break;
  case AST_STRUCT_DECL:
    if (resolver->resolve_expr == true) break;
    type = resolve_struct_decl(resolver, node);
    break;
  case AST_UNION_DECL: assert(0);
  case AST_ENUM_DECL: assert(0);
  case AST_RETURN:
    type = resolve_type(resolver, node->value.return_stmt.value);
    break;
  case AST_INTEGER_LITERAL:
    type = new_type(TYPE_I32);
    break;
  case AST_FLOAT_LITERAL:
    type = new_type(TYPE_F32);
    break;
  case AST_STRING_LITERAL:
    type = new_type(TYPE_STRING);
    break;
  case AST_CHAR_LITERAL:
    type = new_type(TYPE_BYTE);
    break;
  case AST_BOOL_LITERAL:
    type = new_type(TYPE_BOOL);
    break;
  case AST_IDENTIFER:
    type = resolve_identifer(resolver, node);
    break;
  case AST_BINARY:
    type = resolve_binary(resolver, node);
    break;
  case AST_UNARY: assert(0);
  case AST_ASSIGN:
    type = resolve_assign(resolver, node);
    break;
  case AST_DECL: assert(0);
  case AST_CALL:
    type = resolve_call(resolver, node);
    break;
  case AST_MEMBER:
    type = resolve_member(resolver, node);
    break;
  case AST_INDEX: type = resolve_index(resolver, node); break;
  case AST_CAST: type = resolve_cast(resolver, node); break;
  case AST_COMPOUND_LITERAL: assert(0);
  case AST_IF:
    resolve_type(resolver, node->value.if_stmt.condition);
    resolve_block(resolver, node->value.if_stmt.body, NULL);
    
    if (node->value.if_stmt.else_body != NULL) {
      resolve_block(resolver, node->value.if_stmt.else_body, NULL);
    }
    if (node->value.if_stmt.else_if_stmt != NULL) {
      resolve_type(resolver, node->value.if_stmt.else_if_stmt);
      convert_type(resolver, node->value.if_stmt.else_if_stmt);
    }
    break;
    // types
  case AST_TYPE_VOID: return convert_type(resolver, node);
  case AST_TYPE_BOOL: return convert_type(resolver, node);
  case AST_TYPE_BYTE: return convert_type(resolver, node);
  case AST_TYPE_I16: return convert_type(resolver, node);
  case AST_TYPE_I32: return convert_type(resolver, node);
  case AST_TYPE_I64: return convert_type(resolver, node);
  case AST_TYPE_F32: return convert_type(resolver, node);
  case AST_TYPE_F64: return convert_type(resolver, node);
  case AST_TYPE_NAME: return convert_type(resolver, node);
  case AST_TYPE_POINTER: return convert_type(resolver, node);
  case AST_TYPE_ARRAY: return convert_type(resolver, node);


  default:
    printf("======\n");
    printf("%s\n", ast_kind_to_string(node->kind));
    printf("======\n");
    assert(0);
  }
  if (type == NULL) return NULL;

  debug_log("SETTING TYPE %s\n", type_kind_name(type->kind));
  // setting the type in the ast
  node->type = type;
  return type;
}

void type_check_package(TypeResolver *resolver, Package *package) {

  for(int i = 0; i < arrlen(package->declarations); i ++ ){
    switch(package->declarations[i]->kind) {
    case AST_FUNC_DECL:

      // FIXME we should maybe type check this
      if (package->declarations[i]->value.function_decl.is_extern)
        break;
      Symbol *func =
        symbol_lookup_path_str(resolver->scope,
                      package->declarations[i]->type->Function.name);
      if(func == NULL) {
        print_ast(package->declarations[i], 0);
        log_span(package->declarations[i]->span, "Couldn't find function symbol\n");
      }
      
      assert(func != NULL);
      if(func->scope != NULL) {
        SymbolTable *old = resolver->scope;
        resolver->scope = func->scope;
        resolve_type(resolver, package->declarations[i]);
        resolver->scope = old;
      }
      break;
    default:
      break;
    }
  }
}
