#include "parser.h"
#include "../include/stb_ds.h"
#include "../include/sb.h"
#include "ast.h"
#include "lexer.h"
#include "utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>


Token parser_advance(Parser *p) {
  if(p->pos > arrlen(p->tokens)) return (Token) {TOKEN_INVALID};
  Token t = p->tokens[p->pos];
  p->pos += 1;
  return t;
}
Token parser_peek(Parser *p) {
  if(p->pos > arrlen(p->tokens)) return (Token) {TOKEN_INVALID};
  Token t = p->tokens[p->pos];
  return t;
}
Token parser_previous(Parser *p) {
  if(p->pos > arrlen(p->tokens)) return (Token) {TOKEN_INVALID};
  if(p->pos == 0) return (Token) {TOKEN_INVALID};
  Token t = p->tokens[p->pos-1];
  return t;
}
Token parser_next(Parser *p) {
  if(p->pos+1 >= arrlen(p->tokens)) return (Token){TOKEN_INVALID};
  Token t = p->tokens[p->pos+1];
  return t;
}
Token parser_expect(Parser *p, TokenKind kind) {
  Token t = parser_advance(p);
  if (t.kind != kind) {
    log_span(parser_peek(p).span, "unexpected token. wanted '%s' but got '%s'\n", token_kind_to_string(kind), token_kind_to_string(t.kind));
    return (Token){TOKEN_INVALID, "",t.span};
  }
  return t;
}

void print_depth(int depth) {
  for (int i = 0; i < depth; i ++) debug_log(" ");
}

void print_func_decl(FunctionDecl decl, int depth) {
  debug_log("%sFunction Decl (%s) %s\n", decl.is_extern ? "extern ": "",  decl.name, decl.visibility == VIS_PRIVATE ? "private" : "public");
  for (size_t i = 0; i < arrlen(decl.parameters); i ++) {
    print_ast(decl.parameters[i], depth+1);
  }
  if (decl.body == NULL) return;
  print_ast(decl.body, depth+1);

}

void print_type(Ast *ast, int depth) {
  print_depth(depth);
  switch (ast->kind) {
  case AST_TYPE_POINTER:
    debug_log("*");
    print_type(ast->value.pointer_type.to, 0);
    break;
  case AST_TYPE_NAME:
    debug_log("%s\n", ast->value.named_type.name);
    break;
  case AST_TYPE_VOID:
  case AST_TYPE_BOOL:
  case AST_TYPE_BYTE:
  case AST_TYPE_I16:
  case AST_TYPE_I32:
  case AST_TYPE_I64:
  case AST_TYPE_F32:
  case AST_TYPE_F64:
    debug_log("%s\n", ast_kind_to_string(ast->kind));
    break;
  default:
    break;
  }
  
}

void print_ast(Ast *ast, int depth) {
  if (ast == NULL) return;
  print_depth(depth);
  switch (ast->kind) {
  case AST_MEMBER:
    debug_log("Member access\n");
    print_ast(ast->value.member_expr.left, depth+1);
    print_depth(depth+1);
    debug_log("Member %s", ast->value.member_expr.member);
    debug_log("\n");
    break;
  case AST_FUNC_DECL:
    print_func_decl(ast->value.function_decl, depth+1);
    break;
  case AST_BLOCK:
    debug_log("Block\n");
    if (ast->value.block_stmt.stmts == NULL) break;
    for (size_t i = 0; i < arrlen(ast->value.block_stmt.stmts); i ++) {
      print_ast(ast->value.block_stmt.stmts[i], depth+1);
    }    
    break;
  case AST_CALL:
    debug_log("Call\n");
    print_ast(ast->value.call_expr.left, depth+1);
    for(int i = 0; i < arrlen(ast->value.call_expr.parameters); i ++) {
      print_ast(ast->value.call_expr.parameters[i], depth+1);
    }
    break;
  case AST_DECL:
    debug_log("Variable Decl (%s) %s\n",
              ast->value.variable_decl.type != NULL ?
              ast_kind_to_string(ast->value.variable_decl.type->kind) :
              "unknown type",
              ast->value.variable_decl.visibility == VIS_PRIVATE ? "private" : "public"
             );
    if(ast->value.variable_decl.type != NULL)
      print_type(ast->value.variable_decl.type, depth+1);
    if (ast->value.variable_decl.left != NULL)
      print_ast(ast->value.variable_decl.left, depth+1);
    if (ast->value.variable_decl.initlizer != NULL)
      print_ast(ast->value.variable_decl.initlizer, depth+1);
    break;
  case AST_ASSIGN:
    debug_log("Variable Assign\n");
    print_ast(ast->value.assign_expr.left, depth+1);
    print_ast(ast->value.assign_expr.value, depth+1);
    break;
  case AST_IDENTIFER:
    debug_log("Identifer (%s)\n", ast->value.identifer_expr.value);
    break;
  case AST_STRING_LITERAL:
    debug_log("String (%s)\n", ast->value.string_expr.value);
    break;
  case AST_INTEGER_LITERAL:
    debug_log("Integer (%d)\n", ast->value.int_expr.value);
    break;
  case AST_FLOAT_LITERAL:
    debug_log("Float (%f)\n", ast->value.float_expr.value);
    break;
  case AST_RETURN:
    debug_log("Return\n");
    print_ast(ast->value.return_stmt.value, depth+1);
    break;
  case AST_BINARY:
    debug_log("Binary\n");
    print_ast(ast->value.binary_expr.left, depth+1);
    for (int i = 0; i < depth+1; i ++) debug_log(" ");
    print_token(ast->value.binary_expr.operator);
    print_ast(ast->value.binary_expr.right, depth+1);
  default:
    debug_log("\n");
    break;
  }

}

bool is_variable_decl(Parser *p) {
  Token t = parser_peek(p);
  if (t.kind == TOKEN_PRIVATE || t.kind == TOKEN_PUBLIC) {
    p->pos ++;
    if (is_variable_decl(p)) return true;
    p->pos --;
    return false;
  }
  else if (parser_next(p).kind == TOKEN_COLON) {
    debug_log("It is\n");
    return true;
  }
  return false;
}

bool is_function_decl(Parser* p) {
  if (parser_peek(p).kind == TOKEN_FUNC ||
      parser_peek(p).kind == TOKEN_EXTERN) return true;

  if (parser_peek(p).kind == TOKEN_PRIVATE ||
      parser_peek(p).kind == TOKEN_PUBLIC) {
    p->pos ++;
    if (is_function_decl(p)) return true;
    p->pos --;
  }
  return false;
}

bool is_struct_decl(Parser* p) {
  if (parser_peek(p).kind == TOKEN_STRUCT) return true;

  if (parser_peek(p).kind == TOKEN_PRIVATE ||
      parser_peek(p).kind == TOKEN_PUBLIC) {
    p->pos ++;
    if (is_struct_decl(p)) return true;
    p->pos --;
  }
  return false;
}


bool parser_is(Parser *p, TokenKind kind) {
  //print_token(parser_peek(p));
  if (parser_peek(p).kind == kind) {
    debug_log("parser is \n");
    parser_advance(p);
    return true;
  }
  return false;
}

Ast *parse_type(Parser *p) {
  Ast *ast = malloc(sizeof(Ast));

  Token next = parser_advance(p);
  print_token(next);
  switch (next.kind) {
  case TOKEN_BYTE:
    ast->kind = AST_TYPE_BYTE;
    break;
  case TOKEN_I16:
    ast->kind = AST_TYPE_I16;
    break;
  case TOKEN_I32:
    ast->kind = AST_TYPE_I32;
    break;
  case TOKEN_F32:
    ast->kind = AST_TYPE_F32;
    break;
  case TOKEN_F64:
    ast->kind = AST_TYPE_F64;
    break;
  case TOKEN_VOID:
    ast->kind = AST_TYPE_VOID;
    break;
  case TOKEN_IDENTIFER:
    ast->kind = AST_TYPE_NAME;
    ast->value.named_type.name = next.lexeme;
    break;
  case TOKEN_STAR:
    ast->kind = AST_TYPE_POINTER;
    ast->value.pointer_type.to = parse_type(p);
    break;

  default:
    log_span(next.span, "No type\n");
    break;
  }

  return ast;
}

Token parser_skip(Parser *p, TokenKind kind) {
  while (parser_peek(p).kind == kind) {
    parser_advance(p);
  }
  return parser_peek(p);
}


Ast *new_binary_expr(Ast* left, Ast* right, Token operator) {
  Ast *binary = malloc(sizeof(Ast));
  binary->kind = AST_BINARY;
  binary->value.binary_expr = (BinaryExpr){left, right, operator};
  return binary;
}

Ast *parse_primary(Parser *p) {
  Ast *ast = malloc(sizeof(Ast));
  Token token = parser_advance(p);
  debug_log("primary -- ");
  print_token(token);
  

  switch (token.kind) {
  case TOKEN_INTEGER_LITERAL:
    debug_log("Primary int\n");
    ast->kind = AST_INTEGER_LITERAL;
    ast->value.int_expr = (IntExpr){
      atoi(token.lexeme)
    };
    return ast;

  case TOKEN_FLOAT_LITERAL:
    debug_log("Primary float\n");
    ast->kind = AST_FLOAT_LITERAL;
    ast->value.float_expr = (FloatExpr){
      atof(token.lexeme)
    };
    return ast;
  case TOKEN_STRING_LITERAL:
    debug_log("Primary string literal %s\n", token.lexeme);
    ast->kind = AST_STRING_LITERAL;
    ast->value.string_expr = (StringExpr){
      token.lexeme
    };
    return ast;
  case TOKEN_IDENTIFER:
    debug_log("Primary identifer %s\n", token.lexeme);
    ast->kind = AST_IDENTIFER;
    ast->value.identifer_expr = (IdentiferExpr){
      token.lexeme
    };
    return ast;

  default:
    debug_log("Primary error\n");
    log_span(token.span, "Primary error\n");
    return NULL;
  }

  // return left;
  return NULL;
}

Ast *parse_postfix(Parser *p) {
  debug_log("TODO IMPLEMENT postfix\n");
  Ast *left = parse_primary(p);
  while (1) {
    Token token = parser_peek(p);
    print_token(token);
    // DEREFERANCE
    // FIXME dereferance should be star
    if (token.kind == TOKEN_FUNC) {
      panic("TODO DEREFERANCE");
    }
    else if (token.kind == TOKEN_DOT) {
      parser_advance(p);
      Token id = parser_expect(p, TOKEN_IDENTIFER);
      Ast *left_ = left;
      left = malloc(sizeof(Ast));

      left->kind = AST_MEMBER;
      left->value.member_expr = (MemberAccessExpr){0};
      left->value.member_expr.left = left_;
      left->value.member_expr.member = (const char*) id.lexeme;
      parser_skip(p, TOKEN_SEMICOLON);
    }
    else if (token.kind == TOKEN_LPAR) {
      parser_advance(p);
      Ast *left_ = left;
      left = malloc(sizeof(Ast));
      left->kind = AST_CALL;
      left->value.call_expr = (CallExpr){0};
      left->value.call_expr.left = left_;

      if (parser_peek(p).kind != TOKEN_RPAR) {
        do{
          Ast *var = parse_or(p);
          debug_log("PARAMETER FOUND\n");
          print_ast(var, 0);
          debug_log("================\n");
          arrput(left->value.call_expr.parameters, var);
        } while (parser_is(p, TOKEN_COMMA));
      }
      parser_expect(p, TOKEN_RPAR);
    }
    else if (token.kind == TOKEN_LBRACK) {
      panic("TODO subscript");
    }
    else {
      break;
    }
  }
  return left;
}

Ast *parse_term(Parser *p) {
    Ast *left = parse_postfix(p);

    while (1) {
        Token token = parser_peek(p);

        if (token.kind != TOKEN_STAR &&
            token.kind != TOKEN_SLASH) {
            break;
        }

        debug_log("Found operators star slash\n");
        parser_advance(p);

        Ast *right = parse_postfix(p);
        left = new_binary_expr(left, right, token);
    }

    return left;
}

Ast *parse_additive(Parser *p) {
    Ast *left = parse_term(p);

    while (1) {
        Token token = parser_peek(p);

        if (token.kind != TOKEN_PLUS &&
            token.kind != TOKEN_MINUS) {
            break;
        }

        debug_log("Found operators plus minus\n");
        parser_advance(p);

        Ast *right = parse_term(p);
        left = new_binary_expr(left, right, token);

    }

    return left;
}


Ast *parse_condition(Parser *p) {
  Ast *left = parse_additive(p);

  Token token = parser_peek(p);
  if (token.kind == TOKEN_LESS  || token.kind == TOKEN_GREATER ||
      token.kind == TOKEN_EQUAL || token.kind == TOKEN_LE      ||
      token.kind == TOKEN_GE    || token.kind == TOKEN_NOTEQUAL) {
    Ast* right = parse_expression(p);
    left = new_binary_expr(left, right, token);
  }

  return left;
}

Ast *parse_and(Parser *p) {
  Ast *left = parse_condition(p);

  while (1) {
    Token token = parser_peek(p);

    if (token.kind != TOKEN_AND) {
      break;
    }

    debug_log("Found or operator\n");
    parser_advance(p);

    Ast *right = parse_term(p);
    left = new_binary_expr(left, right, token);
  }

  return left;
}


Ast *parse_or(Parser *p) {
  Ast *left = parse_and(p);

  while (1) {
    Token token = parser_peek(p);

    if (token.kind != TOKEN_OR) {
      break;
    }

    debug_log("Found or operator\n");
    parser_advance(p);

    Ast *right = parse_term(p);
    left = new_binary_expr(left, right, token);
  }

  return left;
}

Visibility parse_visibility(Parser *p) {
  debug_log("---------------\n");
  print_token(parser_previous(p));
  debug_log("-------++------\n");
  if (parser_previous(p).kind == TOKEN_PUBLIC){
    return VIS_PUBLIC;
  }
  return VIS_PRIVATE;    
}

Ast *parse_variable_decl(Parser *p) {
  Visibility visibility = parse_visibility(p);
  Ast *left_ = parse_or(p);
  Ast *left = malloc(sizeof(Ast));
  left->kind = AST_VAR_DECL;
  left->value.variable_decl = (VariableDecl) {0};
  left->value.variable_decl.left = left_;
  left->value.variable_decl.visibility = visibility;

  
  if (parser_advance(p).kind != TOKEN_COLON) {
    panic("EXPECTED COLON WHEN VARIABLE DECL");
  }
  // if next isnt equals we should try to parse a type
  if (parser_peek(p).kind != TOKEN_ASSIGN) {
    Ast *type = parse_type(p);
    left->value.variable_decl.type = type;
  }
  // if next is assign we should try to parse initlizer
  if (parser_is(p, TOKEN_ASSIGN) == true) {
    debug_log("We should guess type of initlizer\n");

    Ast *initlizer = parse_expression(p);
    debug_log("after0\n");
    left->value.variable_decl.initlizer = initlizer;
  }

  return left;
}

Ast *parse_assignment(Parser* p) {
  Ast* left = parse_or(p);
  if (parser_is(p, TOKEN_ASSIGN)) {
    Ast *left_ = left;
    left = malloc(sizeof(Ast));
    left->kind = AST_ASSIGN;
    left->value.assign_expr = (AssignExpr) {
      left_,
      parse_or(p)
    };
  }
  return left;
}

Ast *parse_expression(Parser *p) {
  debug_log("Parsing expresstion\n");
  Ast *left = parse_assignment(p);
  debug_log("After\n");
  parser_skip(p, TOKEN_SEMICOLON);

  print_ast(left,0);

  return left;
}

Ast *parse_return(Parser *p) {
  if (!parser_is(p, TOKEN_RETURN))
    panic("TODO parse_return error");

  Ast* ret = malloc(sizeof(Ast));
  ret->kind = AST_RETURN;
  ret->value.return_stmt = (ReturnStmt){0};

  ret->value.return_stmt.value = parse_expression(p);

  return ret;
}

Ast *parse_package_stmt(Parser *p) {
  parser_expect(p, TOKEN_PACKAGE);
  Ast *package = malloc(sizeof(Ast));
  package->kind = AST_PACKAGE;
  
  StringBuilder sb = {0};
  Token t = parser_expect(p, TOKEN_IDENTIFER);
  
  if (t.kind == TOKEN_INVALID) package->kind = AST_INVALID;
  
  sb_append(&sb, t.lexeme);
  while (parser_advance(p).kind == TOKEN_DOT) {
    sb_append(&sb, ".");
    t = parser_expect(p, TOKEN_IDENTIFER);
    sb_append(&sb, t.lexeme);
    if (t.kind == TOKEN_INVALID) package->kind = AST_INVALID;
    
  }

  package->value.package_stmt.value = sb_concat(&sb);
  return package;
}

Ast *parse_stmt(Parser *p) {
  // MAYBE should functions be able to be declared in blocks?
  if (parser_peek(p).kind == TOKEN_FUNC) {
    //return parse_function(p);
    panic("TODO function");
  }
  else if (parser_peek(p).kind == TOKEN_IF) {
    panic("TODO if parsing");
  }
  else if (parser_peek(p).kind == TOKEN_FOR) {
    panic("TODO for parsing");
  }
  else if (parser_peek(p).kind == TOKEN_WHILE) {
    panic("TODO while parsing");
  }
  else if (parser_peek(p).kind == TOKEN_RETURN) {
    return parse_return(p);
  }
  else if (is_variable_decl(p)) {
    debug_log("parser decl\n");
    return parse_variable_decl(p);
  }
  else if (parser_peek(p).kind != TOKEN_EOF) {
    return parse_expression(p);
  }
  
  return 0;
}

Ast *parse_block(Parser *p) {
  parser_expect(p, TOKEN_LCBRACK);

  Ast *block = malloc(sizeof(Ast));
  block->kind = AST_BLOCK;
  block->value.block_stmt = (BlockStmt){0};
  block->value.block_stmt.stmts = NULL;

  
  // parse statements
  while(parser_peek(p).kind != TOKEN_RCBRACK) {
    debug_log("parse stmt in block\n");
    Ast *stmt = parse_stmt(p);
    parser_skip(p, TOKEN_SEMICOLON);
    arrput(block->value.block_stmt.stmts, stmt);
  }

  parser_expect(p, TOKEN_RCBRACK);
  return block;
}


Ast *parse_function(Parser *p) {
  debug_log("=====parsing function =====\n");
  Visibility visibility = parse_visibility(p);

  parser_skip(p, TOKEN_PRIVATE);
  parser_skip(p, TOKEN_PUBLIC);

  if (parser_peek(p).kind != TOKEN_FUNC && parser_peek(p).kind != TOKEN_EXTERN)
    log_span(parser_peek(p).span, "Must start with func\n");

  
  Ast* func = malloc(sizeof(Ast));
  func->kind = AST_FUNC_DECL;
  func->value.function_decl = (FunctionDecl){0};
  func->value.function_decl.parameters = NULL;
  func->value.function_decl.visibility = visibility;
  
  // if its extern we have to advance extra
  if (parser_peek(p).kind == TOKEN_EXTERN){
    parser_expect(p, TOKEN_FUNC);
    func->value.function_decl.is_extern = true;
  }


  parser_advance(p);

  func->value.function_decl.name = (const char*)parser_expect(p, TOKEN_IDENTIFER).lexeme;
  parser_expect(p, TOKEN_LPAR);
  if (parser_peek(p).kind != TOKEN_RPAR) {
    do{
      Ast *var = parse_variable_decl(p);
      debug_log("PARAMETER FOUND\n");
      print_ast(var, 0);
      debug_log("================\n");
      arrput(func->value.function_decl.parameters, var);
    } while (parser_is(p, TOKEN_COMMA));
  }

  parser_expect(p, TOKEN_RPAR);

  // MAYBE be optional with return type
  parser_expect(p, TOKEN_COLON);
  Ast* ret_type = parse_type(p);
  func->value.function_decl.return_type = ret_type;

  if (parser_peek(p).kind == TOKEN_LCBRACK) {
    Ast *block = parse_block(p);
    func->value.function_decl.body = block;
  }

  
  return func;
}

Ast *parse_struct_decl(Parser *p) {

  Visibility visibility = parse_visibility(p);

  parser_expect(p, TOKEN_STRUCT);
  Token identifer = parser_expect(p, TOKEN_IDENTIFER);
  parser_expect(p, TOKEN_LCBRACK);

  Ast *struc = malloc(sizeof(Ast));
  struc->kind = AST_STRUCT_DECL;
  struc->value.struct_decl = (StructDecl){0};
  struc->value.struct_decl.name = identifer.lexeme;
  struc->value.struct_decl.members = NULL;
  struc->value.struct_decl.visibility = visibility;

  
  while (parser_peek(p).kind != TOKEN_RCBRACK) {
    Ast* var = parse_variable_decl(p);
    arrput(struc->value.struct_decl.members,var);
    parser_skip(p, TOKEN_SEMICOLON);
  }

  parser_expect(p, TOKEN_RCBRACK);

  return struc;
}


Package *parse_package(Parser *p) {
  Package *package = malloc(sizeof(Package));
  package->functions = NULL;
  package->structs = NULL;
  package->variables = NULL;


  Ast *package_stmt = parse_package_stmt(p);
  if (package == NULL) log_span(parser_peek(p).span, "NO PACKAGE FOUND");
  package->package = package_stmt->value.package_stmt;
  parser_skip(p, TOKEN_SEMICOLON);
  
  while (parser_peek(p).kind != TOKEN_EOF && parser_peek(p).kind != TOKEN_INVALID)  {
    if (is_function_decl(p)) {
      debug_log("parsing funcion\n");      
      arrput(package->functions, parse_function(p)->value.function_decl);
    }
    else if (is_struct_decl(p)) {
     arrput(package->structs, parse_struct_decl(p)->value.struct_decl); 
    }
    else if (is_variable_decl(p)) {
      debug_log("parsing var\n");
      print_token(parser_next(p));
      Ast *var = parse_variable_decl(p);
      arrput(package->variables, var->value.variable_decl);
    }
    else {
      log_span(parser_peek(p).span,"unexpected token when parsing package\n");
      print_token(parser_peek(p));
      break;
    }
    parser_skip(p, TOKEN_SEMICOLON);
  }
  
  return package;
}

void free_ast(Ast *ast) {

}
