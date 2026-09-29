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
#include "./llvm.h"

LLVMTypeRef create_struct_decl(LLVMGenerator *lg, StructDecl struc);
LLVMTypeRef create_struct_decl_type(LLVMGenerator *lg, struct StructType struc);

LLVMTypeRef get_llvm_type(LLVMGenerator *lg, Type *type) {
  switch (type->kind) {
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
    LLVMTypeRef gtype = hmget(lg->types, (char *)type->Struct.name);
    if(gtype == NULL) {
      // It should exist becuase type resolver hasnt crashed
      // se we generat the struct
      return create_struct_decl_type(lg, type->Struct);
    }
    return gtype;
  case TYPE_POINTER:
    panic("TODO GET LLVM POITR");
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

LLVMValueRef gen_block(LLVMGenerator *lg, BlockStmt block) {
  for (int i = 0; i < arrlen(block.stmts); i ++) {
    Ast* stmt = block.stmts[i];
    switch(stmt->kind) {
    case AST_VAR_DECL:
      assert(stmt->type != NULL);
      LLVMTypeRef type = get_llvm_type(lg, stmt->type);
      LLVMValueRef var = LLVMBuildAlloca(lg->builder, type, "var");


      return var;
    default:
      assert(0);
      break;
    }
  }

}

LLVMValueRef create_function(LLVMGenerator *lg, FunctionDecl func) {
  size_t pl = arrlen(func.parameters);
  LLVMTypeRef *params = malloc(sizeof(LLVMTypeRef) * pl);
  for (int i = 0; i < pl; i++) {
    params[i] = get_llvm_type(lg, func.parameters[i]->type);
  }
  LLVMTypeRef fn_type = LLVMFunctionType(lg->i32, params, pl, 0);
  free(params);

  LLVMValueRef function =
    LLVMAddFunction(
                    lg->module,
                    func.name,
                    fn_type
                   );

  if (func.body != NULL) {
    LLVMBasicBlockRef entry =
      LLVMAppendBasicBlockInContext(
                                    lg->context,
                                    function,
                                    "entry"
                                   );
    LLVMPositionBuilderAtEnd(lg->builder, entry);
    gen_block(lg, func.body->value.block_stmt);

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
    m.name = strdup(
                    decl.members[i]->value.variable_decl.left->value.identifer_expr.value);
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
    printf("Type: %d\n", struc.members[i].type);

    LLVMTypeRef llvm_type = get_llvm_type(lg, struc.members[i].type);
    field_types[i] = llvm_type;
  }
  
  LLVMStructSetBody(struct_type, field_types, arrlen(struc.members), 0);
  
  hmput(lg->types, (char* )struc.name, struct_type);
  
  return struct_type;
}


void gen_package(Package *package) {
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

  lg.context = context;
  lg.module = module;
  lg.builder = builder;

  // Begin with generation the declerations in the package
  for(int i = 0; i < arrlen(package->declarations); i ++ ){

    switch(package->declarations[i]->kind) {
    case AST_FUNC_DECL:
      create_function(&lg, package->declarations[i]->value.function_decl);
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

  LLVMDisposeMessage(ir);
  LLVMDisposeBuilder(builder);
  LLVMDisposeModule(module);
  LLVMContextDispose(context);

}
