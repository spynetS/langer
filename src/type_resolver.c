#include "type_resolver.h"
#include "ast.h"
#include "symbol_table.h"
#include "type.h"
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
    Ast *name = atype->value.named_type.name;
    Symbol *sym = NULL;
    if (name->kind == AST_IDENTIFER) {
      sym = symbol_lookup(resolver->scope, name->value.identifer_expr.value);
    } else {
      print_ast(name, 0);
      sym = symbol_lookup_path(resolver->scope, name->value.member_expr);
    }
    if (sym == NULL) {
      log_span(name->span, "error: symbol 'TODO' could not be found \n");
    } else if (sym->type == NULL) {
      // if its type is null we resolve it
      sym->type = get_type(resolver, sym->node);
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
  type->Struct.members = NULL;
  node->type = type;

  for (int i = 0; i < arrlen(decl.members); i++) {
    Member m = {0};
    m.name = strdup(
        decl.members[i]->value.variable_decl.left->value.identifer_expr.value);
    m.type = get_type(resolver, decl.members[i]);
    arrput(type->Struct.members, m);
  }

  return type;
}

Type *resolve_call(TypeResolver *resolver, Ast *node) {
  assert(node->kind == AST_CALL);

  MemberAccessExpr path = node->value.call_expr.left->value.member_expr;
  Symbol *sym = symbol_lookup_path(resolver->scope, path);
  if (sym == NULL) {
    log_span(node->span, "error: Symbol not found\n");
    assert(0);
  }

  print_symbol(sym,0);

  return sym->type->Function.return_type;
}


Type *resolve_member(TypeResolver *resolver, Ast *node) {
    assert(node->kind == AST_MEMBER);

    MemberAccessExpr expr = node->value.member_expr;

    Type *left_type = get_type(resolver, expr.left);

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

Type *resolve_func_decl (TypeResolver *resolver, Ast *node) {

  FunctionDecl decl = node->value.function_decl;
  
  Type *ftype = new_type(TYPE_FUNCTION);
  ftype->Function.return_type = resolve_type(resolver, decl.return_type);
  ftype->Function.parameters = NULL;

  for(int i = 0; i < arrlen(decl.parameters); i ++) {
    Type *type = get_type(resolver, decl.parameters[i]);
    arrput(ftype->Function.parameters, type);
  }

  if (decl.body != NULL && resolver->resolve_expr) {
    for (int i = 0; i < arrlen(decl.body->value.block_stmt.stmts); i++) {
      Type *type = get_type(resolver, decl.body->value.block_stmt.stmts[i]);
    }
  }

  node->type = ftype;
  return ftype;
}

Type *can_cast(Type *a, Type *b) {
  return a;
}

Type *resolve_assign(TypeResolver *resolver, Ast *node) {
  assert(node->kind == AST_ASSIGN);

  Type *left_type = get_type(resolver, node->value.assign_expr.left);

  Type *value_type = get_type(resolver, node->value.assign_expr.value);
  node->type = value_type;

  if (can_cast(left_type, value_type) == NULL) {
    assert(0);
  }

  return value_type;
}

Type *resolve_identifer(TypeResolver *resolver, Ast *node) {
  assert(node->kind == AST_IDENTIFER);

  Symbol *sym = symbol_lookup(resolver->scope, node->value.identifer_expr.value);
  if (sym == NULL) {
    log_span(node->span, "error: Symbol not found\n");
  }

  return sym->type;
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
  case AST_IDENTIFER:
    type = resolve_identifer(resolver, node);
    break;
  case AST_BINARY: assert(0);
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

void type_check_package(TypeResolver *resolver, Package *package) {
    for(int i = 0; i < arrlen(package->declarations); i ++ ){
      switch(package->declarations[i]->kind) {
      case AST_FUNC_DECL:
        get_type(resolver, package->declarations[i]);
        break;
      default:
        break;
      }
    }

}

