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
LLVMTypeRef create_function_type(LLVMGenerator *lg, struct FunctionType func);
LLVMValueRef create_function(LLVMGenerator *lg, Ast *ast);

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

void save_type(LLVMGenerator *lg, const char* name, LLVMTypeRef ltype){
  hmput(lg->types, name, ltype);
}

LLVMTypeRef get_type(LLVMGenerator *lg, const char* name) {
  return hmget(lg->types, name);
}


LLVMTypeRef get_llvm_type(LLVMGenerator *lg, Type *type) {
  switch (type->kind) {
  case TYPE_VOID:
    return LLVMVoidType();    
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
  //  size_t pl = arrlen(expr.parameters);
  LLVMValueRef args[0];

  char cname[256];
  if (return_type->kind != TYPE_VOID) {
    sprintf(cname, "val");
  } else {
    sprintf(cname, "");
  }

  LLVMValueRef result =
    LLVMBuildCall2(
                   lg->builder,
                   ftype,
                   function,
                   args,
                   0,
                   cname
                  );

  return result;
}

LLVMValueRef create_stmt(LLVMGenerator *lg, Ast *stmt) {
  print_ast(stmt, 0);
  switch(stmt->kind) {
  case AST_RETURN:
    // TODO maybe create llvm return here?
    return create_stmt(lg, stmt->value.return_stmt.value);
  case AST_INTEGER_LITERAL:
    return LLVMConstInt(lg->i32, stmt->value.int_expr.value, false);
  case AST_VAR_DECL: {
    assert(stmt->type != NULL);
    printf("here\n");
    print_ast(stmt, 0);
    LLVMTypeRef type = get_llvm_type(lg, stmt->type);
    LLVMValueRef var = LLVMBuildAlloca(lg->builder, type, "var");

    if(stmt->value.variable_decl.initlizer != NULL) {
      LLVMValueRef value = create_stmt(lg, stmt->value.variable_decl.initlizer);
      return LLVMBuildStore(lg->builder, value, var);
    }

    return var;
  }
  case AST_CALL: {
    assert(stmt->type != NULL);
    return create_call(lg, stmt->value.call_expr);
  }
    
  default:
    //assert(0);
    break;
  }

}

LLVMValueRef gen_block(LLVMGenerator *lg, BlockStmt block) {
  for (int i = 0; i < arrlen(block.stmts); i ++) {
    Ast* stmt = block.stmts[i];
    LLVMValueRef val = create_stmt(lg, stmt);
    if (stmt->kind == AST_RETURN)
      return val;
  }
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
    printf("Type: %d\n", struc.members[i].type);

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

    LLVMBuildCall2(
        lg->builder,
        user_main_type,
        user_main,
        NULL,
        0,
        ""
    );

    // Return success to the operating system.
    LLVMBuildRet(
        lg->builder,
        LLVMConstInt(i32, 0, false)
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

  LLVMDisposeMessage(ir);
  LLVMDisposeBuilder(builder);
  LLVMDisposeModule(module);
  LLVMContextDispose(context);

}
