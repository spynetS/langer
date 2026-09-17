#include "type_resolver.h"
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
  case AST_VAR_DECL:
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
      assert(0);
    }
    assert(sym->type != NULL);
    return sym->type;
    break;
  }
  return type;
}

Type *resolve_var_decl (TypeResolver *resolver, Ast *node) {
  if (node->value.variable_decl.type != NULL ) {
    return resolve_type(resolver, node->value.variable_decl.type);
  }
  else if (node->value.variable_decl.initlizer != NULL) {
    return get_type(resolver, node->value.variable_decl.initlizer);
  }
}

Type *resolve_struct_decl (TypeResolver *resolver, Ast *node) {
  StructDecl decl = node->value.struct_decl;

  Type *type = new_type(TYPE_STRUCT);
  type->Struct.name = decl.name;
  return type;
}

Type *resolve_func_decl (TypeResolver *resolver, Ast *node) {

  FunctionDecl decl = node->value.function_decl;

  Type *type = new_type(TYPE_FUNCTION);
  type->Function.return_type = resolve_type(resolver, decl.return_type);
  type->Function.parameters = NULL;
  for(int i = 0; i < arrlen(decl.parameters); i ++) {
    Type *type = get_type(resolver, decl.parameters[i]);
    arrput(type->Function.parameters, type);
  }
  
  return type;
}

Type *get_type(TypeResolver *resolver, Ast *node) {

  switch(node->kind) {
  case AST_VAR_DECL: return resolve_var_decl(resolver, node);
  case AST_FUNC_DECL: return resolve_func_decl(resolver, node);
  case AST_STRUCT_DECL: return resolve_struct_decl(resolver, node);
  case AST_UNION_DECL: assert(0);
  case AST_ENUM_DECL: assert(0);

  case AST_RETURN: return get_type(resolver, node->value.return_stmt.value);

  case AST_INTEGER_LITERAL: return new_type(TYPE_I32);
  case AST_FLOAT_LITERAL: return new_type(TYPE_F32);
  case AST_STRING_LITERAL: return new_type(TYPE_STRING);
  case AST_CHAR_LITERAL: return new_type(TYPE_BYTE);
  case AST_BOOL_LITERAL: return new_type(TYPE_BOOL);
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
  return NULL;
}
