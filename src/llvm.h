#ifndef LLVM_H
#define LLVM_H

#include <llvm-c/Core.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/Target.h>
#include <llvm-c/TargetMachine.h>
#include <llvm-c/ExecutionEngine.h>

#include "parser.h"

typedef struct {
  LLVMContextRef context;
  LLVMModuleRef module;
  LLVMBuilderRef builder;

  // helpers to get types without generating them
  LLVMTypeRef byte;
  LLVMTypeRef i16;
  LLVMTypeRef i32;
  LLVMTypeRef i64;
  LLVMTypeRef f32;
  LLVMTypeRef f64;

} LLVMGenerator;


void gen_program(Program *program);

#endif


/*

  example llvm builder code



  LLVMTypeRef params[] = {
    lg.i32,
    lg.i32,
  };

  LLVMTypeRef fn_type =
    LLVMFunctionType(
                     lg.i32,
                     params,
                     2,
                     0
                    );

  LLVMValueRef function =
    LLVMAddFunction(
                    module,
                    "main",
                    fn_type
                   );

  LLVMBasicBlockRef entry =
    LLVMAppendBasicBlockInContext(
                                  context,
                                  function,
                                  "entry"
                                 );

  LLVMPositionBuilderAtEnd(builder, entry);

  LLVMValueRef a =
    LLVMGetParam(function, 0);

  LLVMValueRef b =
    LLVMGetParam(function, 1);

  LLVMValueRef result =
    LLVMBuildAdd(
                 builder,
                 a,
                 b,
                 "result"
                );

  LLVMBuildRet(builder, result);

  */
