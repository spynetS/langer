#include <llvm-c/Core.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/Target.h>
#include <llvm-c/TargetMachine.h>
#include <llvm-c/ExecutionEngine.h>

#include <llvm-c/Types.h>
#include <stdio.h>
#include <stdbool.h>

#include "./ast.h"
#include "./utils.h"
#include "../include/stb_ds.h"
#include "./llvm.h"

LLVMTypeRef get_llvm_type(LLVMGenerator lg, Ast *node) {
  switch (node->kind) {
  case AST_TYPE_BYTE:
    return lg.byte;
  case AST_TYPE_I16:
    return lg.i16;
  case AST_TYPE_I32:
    return lg.i32;
  case AST_TYPE_I64:
    return lg.i64;
  case AST_TYPE_F32:
    return lg.f32;
  case AST_TYPE_F64:
    return lg.f64;
  case AST_TYPE_POINTER:
    panic("TODO GET LLVM POITR");
    break;
  case AST_TYPE_ARRAY:
    panic("TODO GET LLVM ARRATYY");
    break;
  default:
    print_ast(node, 0);
    panic("TODO NOT AN TYPE");
    break;
  }
  return NULL;
}

LLVMValueRef create_function(LLVMGenerator lg, FunctionDecl func) {
  size_t pl = arrlen(func.parameters);
  LLVMTypeRef *params = malloc(sizeof(LLVMTypeRef) * pl);
  for (int i = 0; i < pl; i++) {
    params[i] = get_llvm_type(lg, func.parameters[i]);
  }
  LLVMTypeRef fn_type = LLVMFunctionType(lg.i32, params, pl, 0);
  free(params);

  LLVMValueRef function =
    LLVMAddFunction(
                    lg.module,
                    func.name,
                    fn_type
                   );

  if (func.body != NULL) {
    LLVMBasicBlockRef entry =
      LLVMAppendBasicBlockInContext(
                                    lg.context,
                                    function,
                                    "entry"
                                   );

  }

  return function;
}

void gen_package(Package *package) {
  LLVMContextRef context = LLVMContextCreate();

  LLVMModuleRef module =
    LLVMModuleCreateWithNameInContext(
                                      "my_module",
                                      context
                                     );

  LLVMBuilderRef builder =
    LLVMCreateBuilderInContext(context);

  LLVMGenerator lg = {0};
  lg.byte = LLVMInt8TypeInContext(context);
  lg.i16 = LLVMInt16TypeInContext(context);
  lg.i32 = LLVMInt32TypeInContext(context);
  lg.i64 = LLVMInt64TypeInContext(context);
  lg.f32 = LLVMFloatTypeInContext(context);
  lg.f64 = LLVMDoubleTypeInContext(context);


  lg.context = context;
  lg.module = module;
  lg.builder = builder;


  for(int i = 0; i < arrlen(package->functions); i ++ ){
    create_function(lg, package->functions[i]);
  }

  char *ir =
    LLVMPrintModuleToString(module);

  printf("%s\n", ir);

  LLVMDisposeMessage(ir);
  LLVMDisposeBuilder(builder);
  LLVMDisposeModule(module);
  LLVMContextDispose(context);

}
