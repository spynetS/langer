#include <llvm-c/Core.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/Target.h>
#include <llvm-c/TargetMachine.h>
#include <llvm-c/ExecutionEngine.h>

#include <llvm-c/Types.h>
#include <stdio.h>
#include <stdbool.h>
#include <assert.h>

#include "./ast.h"
#include "./type.h"
#include "./utils.h"
#include "../include/stb_ds.h"
#include "lexer.h"
#include "./llvm.h"

LLVMTypeRef create_struct_decl(LLVMGenerator *lg, StructDecl struc);
LLVMTypeRef create_struct_decl_type(LLVMGenerator *lg, struct StructType struc);
LLVMTypeRef create_function_type(LLVMGenerator *lg, struct FunctionType func);
LLVMValueRef create_function(LLVMGenerator *lg, Ast *ast);
LLVMValueRef create_stmt(LLVMGenerator *lg, Ast *stmt);

void member_to_str(char *dst, MemberAccessExpr expr) {
  debug_log("====begin to make member access into string\n");

  snprintf(dst, 256, "%s", expr.member);
  
  Ast* left = expr.left;
  while(left != NULL && left->kind == AST_MEMBER) {

    char tmp[256];
    snprintf(tmp, sizeof(tmp), "%s.%s",
             left->value.member_expr.member, dst);
    snprintf(dst, 256, "%s", tmp);

    left = left->value.member_expr.left;
  }

  if (left != NULL && left->kind == AST_IDENTIFER) {
    char tmp[256];
    snprintf(tmp, sizeof(tmp), "%s.%s",
             left->value.identifer_expr.value, dst);
    snprintf(dst, 256, "%s", tmp);
  }

  printf("%s\n", dst);

  debug_log("====done\n");
}

void save_type(LLVMGenerator *lg, char* name, LLVMTypeRef ltype){
  shput(lg->types, name, ltype);
}

LLVMTypeRef get_type(LLVMGenerator *lg, const char* name) {
  return shget(lg->types, name);
}

LLVMTypeRef get_llvm_type(LLVMGenerator *lg, Type *type) {
  switch (type->kind) {
  case TYPE_VOID:
    return LLVMVoidTypeInContext(lg->context);    
  case TYPE_BYTE:
    return lg->byte;
  case TYPE_I16:
    return lg->i16;
  case TYPE_I32:
    return lg->i32;
  case TYPE_I64:
    return lg->i64;
  case TYPE_F32:
    return lg->f32;
  case TYPE_F64:
    return lg->f64;
  case TYPE_STRUCT:
    debug_log("FINDING STRUCT '%s'\n", type->Struct.name);
    LLVMTypeRef gtype = create_struct_decl_type(lg, type->Struct);
    //get_type(lg, type->Struct.name);
    if(gtype == NULL) {
      // It should exist becuase type resolver hasnt crashed
      // se we generat the struct
      return create_struct_decl_type(lg, type->Struct);
    }
    return gtype;
  case TYPE_POINTER:
    return LLVMPointerType(get_llvm_type(lg, type->Pointer.base), 0);
    break;
  case TYPE_ARRAY:
    panic("TODO GET LLVM ARRATYY");
    break;
  default:
    printf("=============\n");
    printf("%s\n", ast_kind_to_string(type->kind));
    printf("TODO NOT AN LLVM TYPE\n");
    printf("==============\n");
    assert(0);
    break;
  }
  return NULL;
}

LLVMValueRef create_call(LLVMGenerator *lg, CallExpr expr) {

  char name[256];
  Type* return_type = NULL;

  if(expr.left->kind == AST_MEMBER) {
    Symbol *sym = symbol_lookup_path(lg->sroot, expr.left->value.member_expr);
    assert(sym != NULL);
    assert(sym->kind == SYMBOL_FUNCTION);
    snprintf(name, sizeof(name), "%s", sym->type->Function.name);
    return_type = sym->type->Function.return_type;
  } else if (expr.left->kind == AST_IDENTIFER) {
    // becuase the name can be without package prefix
    // foo(), instead of main.foo()
    // we need to find the symvol and use that name
    Symbol *sym = symbol_lookup(lg->sroot, expr.left->value.identifer_expr.value);
    assert(sym != NULL);
    assert(sym->kind == SYMBOL_FUNCTION);
    snprintf(name, sizeof(name), "%s", sym->type->Function.name);
    return_type = sym->type->Function.return_type;
  } else {
    assert(false);
  }

  LLVMValueRef function = LLVMGetNamedFunction(lg->module, name);

  if(function == NULL){
    Symbol *sym = symbol_lookup_path(lg->sroot, expr.left->value.member_expr);
    assert(sym != NULL);
    assert(sym->kind == SYMBOL_FUNCTION);
    return_type = sym->type->Function.return_type;
    LLVMTypeRef fn_type = create_function_type(lg, sym->type->Function);
    function = LLVMAddFunction(
                               lg->module,
                               name,
                               fn_type
                              );
  }

  LLVMTypeRef ftype = LLVMGlobalGetValueType(function);
  size_t pl = arrlen(expr.parameters);
  LLVMValueRef args[pl];
  for(size_t i = 0; i < pl; i ++ ) {
    args[i] = create_stmt(lg, expr.parameters[i]);
  }
  

  char cname[6];
  cname[0] = '\0';
  if (return_type->kind != TYPE_VOID) {
    snprintf(cname, 5, "val");
  } 

  LLVMValueRef result =
    LLVMBuildCall2(
                   lg->builder,
                   ftype,
                   function,
                   args,
                   pl,
                   cname
                  );

  return result;
}

LLVMValueRef create_assign(LLVMGenerator *lg, AssignExpr expr) {

  if (expr.left->kind == AST_IDENTIFER) {
      LLVMValueRef ptr = shget(lg->values, expr.left->value.identifer_expr.value);
      assert(ptr != NULL);
      LLVMValueRef value = create_stmt(lg, expr.value);
      return LLVMBuildStore(lg->builder, value, ptr);
  }
  assert(0);
  return NULL;
}

LLVMValueRef build_add(LLVMGenerator *lg, LLVMValueRef left, LLVMValueRef right, bool f) {
  return f ? LLVMBuildAdd(lg->builder, left, right, "tmp") : LLVMBuildFAdd(lg->builder, left, right, "tmp");
}

LLVMValueRef create_binary(LLVMGenerator *lg, BinaryExpr expr) {

  LLVMValueRef left  = create_stmt(lg, expr.left);
  LLVMValueRef right = create_stmt(lg, expr.right);

  bool floating = false;

  switch (expr.operator) {
  case TOKEN_PLUS:
    return !floating ? LLVMBuildAdd(lg->builder, left, right, "tmp") : LLVMBuildFAdd(lg->builder, left, right, "tmp");
  case TOKEN_MINUS:
    return !floating ? LLVMBuildSub(lg->builder, left, right, "tmp") : LLVMBuildFSub(lg->builder, left, right, "tmp");
  case TOKEN_STAR:
    return !floating ? LLVMBuildMul(lg->builder, left, right, "tmp") : LLVMBuildFMul(lg->builder, left, right, "tmp");
  case TOKEN_SLASH:
    return !floating ? LLVMBuildSDiv(lg->builder, left, right, "tmp") : LLVMBuildFDiv(lg->builder, left, right, "tmp");
  default:
    assert(0);
  }

  return NULL;
}

LLVMValueRef create_stmt(LLVMGenerator *lg, Ast *stmt) {
  print_ast(stmt, 0); 
  switch(stmt->kind) {
  case AST_ASSIGN           : return create_assign(lg, stmt->value.assign_expr);
  case AST_ENUM_DECL        : assert(0); // TODO
  case AST_UNION_DECL       : assert(0); // TODO
  case AST_BLOCK            : assert(0); // TODO
  case AST_IF               : assert(0); // TODO
  case AST_WHILE            : assert(0); // TODO
  case AST_FOR              : assert(0); // TODO
  case AST_EXPR_STMT        : assert(0); // TODO
  case AST_CHAR_LITERAL     : assert(0); // TODO
  case AST_BOOL_LITERAL     : assert(0); // TODO
  case AST_UNARY            : assert(0); // TODO
  case AST_DECL             : assert(0); // TODO
  case AST_INDEX            : assert(0); // TODO
  case AST_CAST             : assert(0); // TODO
  case AST_COMPOUND_LITERAL : assert(0); // TODO
  case AST_MEMBER           : assert(0); // TODO
  case AST_CALL             : return create_call(lg, stmt->value.call_expr);
  case AST_RETURN           : return create_stmt(lg, stmt->value.return_stmt.value);
  case AST_BINARY           : return create_binary(lg, stmt->value.binary_expr);
  case AST_INTEGER_LITERAL  : return LLVMConstInt(lg->i32, stmt->value.int_expr.value, false);
  case AST_FLOAT_LITERAL    : return LLVMConstReal(lg->f32, (double)stmt->value.float_expr.value);


  case AST_STRING_LITERAL   :
    String str = stmt->value.string_expr.value;
    return LLVMBuildGlobalStringPtr(
                             lg->builder,
                             str.data,
                             "str"
                            );
  case AST_IDENTIFER:{
    char *name = stmt->value.identifer_expr.value;
    LLVMTypeRef type = get_type(lg, name);
    LLVMValueRef ptr = shget(lg->values, name);

    assert(ptr != NULL);
    assert(type != NULL);

    return LLVMBuildLoad2(
        lg->builder,
        type,  // The variable's LLVM type
        ptr,
        name
    );
  }
  case AST_VAR_DECL: {
    assert(stmt->type != NULL);

        char *name =
        stmt->value.variable_decl.left->value.identifer_expr.value;

    LLVMTypeRef type = get_llvm_type(lg, stmt->type);
    LLVMValueRef var = LLVMBuildAlloca(lg->builder, type, name);


    if(stmt->value.variable_decl.left->kind == AST_IDENTIFER){
      save_type(lg, name, type);
      shput(lg->values, name, var);
    } else {assert(0);};


    if(stmt->value.variable_decl.initlizer != NULL) {
      LLVMValueRef value = create_stmt(lg, stmt->value.variable_decl.initlizer);
      return LLVMBuildStore(lg->builder, value, var);
    }

    return var;
  }
  default:
    assert(0);
  }
  return NULL;
}

LLVMValueRef gen_block(LLVMGenerator *lg, BlockStmt block) {
  for (int i = 0; i < arrlen(block.stmts); i ++) {
    Ast* stmt = block.stmts[i];
    print_ast(stmt,4);
    LLVMValueRef val = create_stmt(lg, stmt);
    if (stmt->kind == AST_RETURN)
      return val;
  }
  assert(0);
  return NULL;
}

LLVMTypeRef create_function_type(LLVMGenerator *lg, struct FunctionType func) {

  // the parameters
  size_t pl = arrlen(func.parameters);
  LLVMTypeRef *params = malloc(sizeof(LLVMTypeRef) * pl);
  for (int i = 0; i < pl; i++) {
    params[i] = get_llvm_type(lg, func.parameters[i]);
  }

  // create the type
  LLVMTypeRef fn_type = LLVMFunctionType(get_llvm_type(lg, func.return_type), params, pl, 0);
  free(params);
  
  save_type(lg, func.name, fn_type);
  return fn_type;
}

LLVMValueRef create_function(LLVMGenerator *lg, Ast *ast) {
  struct FunctionType func = ast->type->Function;
  assert(func.name != NULL);
  
  assert(func.return_type != NULL);
  LLVMTypeRef fn_type = create_function_type(lg, func);
  // the function value
  LLVMValueRef function =
    LLVMAddFunction(
                    lg->module,
                    func.name,
                    fn_type
                   );
  // if the function has a body we should generate it
  if (ast->value.function_decl.body != NULL) {
    LLVMBasicBlockRef entry =
      LLVMAppendBasicBlockInContext(
                                    lg->context,
                                    function,
                                    "entry"
                                   );
    LLVMPositionBuilderAtEnd(lg->builder, entry);

    LLVMValueRef ret = gen_block(lg, ast->value.function_decl.body->value.block_stmt);
    if(ret != NULL) {
      LLVMBuildRet(lg->builder, ret);
    } else {
      LLVMBuildRetVoid(lg->builder);
    }
  }

  return function;
}

LLVMTypeRef create_struct_decl(LLVMGenerator *lg, StructDecl decl) {
  debug_log("LLVM creating struct decl '%s'\n", decl.name);

  struct StructType struct_type = {0};
  struct_type.name = decl.name;
  struct_type.members = NULL;
  for (int i = 0; i < arrlen(decl.members); i++) {
    Member m = {0};
    m.name = strdup(decl.members[i]->value.variable_decl.left->value.identifer_expr.value);
    m.type = decl.members[i]->type;
    arrput(struct_type.members, m);
  }

  return create_struct_decl_type(lg, struct_type);
}


LLVMTypeRef create_struct_decl_type(LLVMGenerator *lg, struct StructType struc) {
  debug_log("LLVM creating struct decl '%s' type\n", struc.name);
  LLVMTypeRef struct_type = LLVMStructCreateNamed(lg->context, struc.name);


  LLVMTypeRef field_types[arrlen(struc.members)];
  for (size_t i = 0; i < arrlen(struc.members); i ++) {
    LLVMTypeRef llvm_type = get_llvm_type(lg, struc.members[i].type);
    field_types[i] = llvm_type;
  }


  LLVMStructSetBody(struct_type, field_types, arrlen(struc.members), 0);
  
  save_type(lg, struc.name, struct_type);

  return struct_type;
}


void create_entry_point(LLVMGenerator *lg, LLVMValueRef user_main) {
    LLVMTypeRef i32 = LLVMInt32TypeInContext(lg->context);

    // int main()
    LLVMTypeRef main_type = LLVMFunctionType(
        i32,
        NULL,
        0,
        false
    );

    LLVMValueRef entry = LLVMAddFunction(
        lg->module,
        "main",
        main_type
    );

    LLVMBasicBlockRef entry_block =
        LLVMAppendBasicBlockInContext(
            lg->context,
            entry,
            "entry"
        );

    LLVMPositionBuilderAtEnd(lg->builder, entry_block);

    // Call your language's main function.
    LLVMTypeRef user_main_type =
        LLVMGlobalGetValueType(user_main);

    LLVMValueRef ret = LLVMBuildCall2(
        lg->builder,
        user_main_type,
        user_main,
        NULL,
        0,
        "ret"
    );

    // Return success to the operating system.
    LLVMBuildRet(
        lg->builder,
        ret
    );
}

void gen_package(Package *package, SymbolTable *root) {
  LLVMContextRef context = LLVMContextCreate();

  LLVMModuleRef module =
    LLVMModuleCreateWithNameInContext(
                                      package->package.value,
                                      context
                                     );

  LLVMBuilderRef builder =
    LLVMCreateBuilderInContext(context);

  // Setting up the llvm generator and defining types
  LLVMGenerator lg = {0};
  lg.byte = LLVMInt8TypeInContext(context);
  lg.i16 = LLVMInt16TypeInContext(context);
  lg.i32 = LLVMInt32TypeInContext(context);
  lg.i64 = LLVMInt64TypeInContext(context);
  lg.f32 = LLVMFloatTypeInContext(context);
  lg.f64 = LLVMDoubleTypeInContext(context);

  lg.types = NULL;
  lg.values = NULL;

  sh_new_arena(lg.values);   // or sh_new_strdup(lg.values);
  sh_new_arena(lg.types);

  lg.context = context;
  lg.module = module;
  lg.builder = builder;
  lg.sroot = root;

  // Begin with generation the declerations in the package
  for(int i = 0; i < arrlen(package->declarations); i ++ ){

    switch(package->declarations[i]->kind) {
    case AST_FUNC_DECL:
      LLVMValueRef func = create_function(&lg, package->declarations[i]);
      if(strcmp(package->declarations[i]->value.function_decl.name, "main") == 0) {
        create_entry_point(&lg, func);
      }

      break;
    case AST_STRUCT_DECL:
      create_struct_decl(&lg, package->declarations[i]->value.struct_decl);
      break;
    default:
      break;
    }
  }


  char *ir =
    LLVMPrintModuleToString(module);
  printf("%s\n", ir);

  char *error = NULL;

  if (LLVMPrintModuleToFile(module, "main.ll", &error)) {
    fprintf(stderr, "Failed to write LLVM IR: %s\n", error);
    LLVMDisposeMessage(error);
  }

  LLVMDisposeMessage(ir);
  LLVMDisposeBuilder(builder);
  LLVMDisposeModule(module);
  LLVMContextDispose(context);

}
