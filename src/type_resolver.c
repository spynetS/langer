#include "type_resolver.h"
#include "ast.h"
#include "utils.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "../include/stb_ds.h"



Type *new_type(TypeKind kind) {
  Type *type = malloc(sizeof(Type));
  type->kind = kind;
  return type;
}
Type *resolve_type(TypeResolver *resolver, Ast* atype) {
  Type *type = malloc(sizeof(Type));
  switch(atype->kind) {
  case AST_TYPE_POINTER:
    type->kind = TYPE_POINTER;
    type->Pointer.base = resolve_type(resolver, atype->value.pointer_type.to);
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
    Symbol* sym = symbol_lookup(resolver->scope, atype->value.named_type.name);
    if (sym == NULL) {
      printf("error: symbol '%s' could not be found \n", atype->value.named_type.name);
    }
    assert(sym->type != NULL);
    return sym->type;
    break;
  default:
    break;
  }
  return type;
}

Type *resolve_var_decl(TypeResolver *resolver, Ast *node) {
  Type *type = NULL;
  if (node->value.variable_decl.type != NULL ) {
    type =  resolve_type(resolver, node->value.variable_decl.type);
  }
  else if (node->value.variable_decl.initlizer != NULL) {
    type = get_type(resolver, node->value.variable_decl.initlizer);
  }
  node->type = type;
  return type;
}

Type *resolve_struct_decl (TypeResolver *resolver, Ast *node) {
  StructDecl decl = node->value.struct_decl;
  
  Type *type = new_type(TYPE_STRUCT);
  type->Struct.name = decl.name;
  node->type = type;
  return type;
}

Type *resolve_func_decl (TypeResolver *resolver, Ast *node) {

  FunctionDecl decl = node->value.function_decl;
  
  Type *ftype = new_type(TYPE_FUNCTION);
  ftype->Function.return_type = resolve_type(resolver, decl.return_type);
  ftype->Function.parameters = NULL;

  for(int i = 0; i < arrlen(decl.parameters); i ++) {
    Type *type = get_type(resolver, decl.parameters[i]);
    arrput(ftype->Function.parameters, type);
  }

  node->type = ftype;
  return ftype;
}

Type *get_type(TypeResolver *resolver, Ast *node) {

  Type *type = NULL;

  switch(node->kind) {
  case AST_VAR_DECL:
    type = resolve_var_decl(resolver, node);
    break;
  case AST_FUNC_DECL:
    type = resolve_func_decl(resolver, node);
    break;
  case AST_STRUCT_DECL:
    type = resolve_struct_decl(resolver, node);
    break;
  case AST_UNION_DECL: assert(0);
  case AST_ENUM_DECL: assert(0);

  case AST_RETURN:
    type = get_type(resolver, node->value.return_stmt.value);
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
  case AST_IDENTIFER: assert(0);
  case AST_BINARY: assert(0);
  case AST_UNARY: assert(0);
  case AST_ASSIGN: assert(0);
  case AST_DECL: assert(0);
  case AST_CALL: assert(0);
  case AST_MEMBER: assert(0);
  case AST_INDEX: assert(0);
  case AST_CAST: assert(0);
  case AST_COMPOUND_LITERAL: assert(0);

  default:
    printf("======\n");
    printf("%s\n", ast_kind_to_string(node->kind));
    printf("======\n");
    assert(0);
  }
  printf("SETTING TYPE %s\n", type_kind_name(type->kind));
  if (type == NULL) return NULL;
  // setting the type in the ast
  node->type = type;
  
  return type;
}
