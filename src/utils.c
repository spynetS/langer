#include "lexer.h"
#include "symbol_table.h"
#include "ast.h"
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <stdarg.h>

const char *token_kind_to_string(TokenKind kind)
{
  switch (kind) {
    // Keywords
    case TOKEN_PACKAGE: return "TOKEN_PACKAGE";
    case TOKEN_IMPORT:  return "TOKEN_IMPORT";
    case TOKEN_PRIVATE: return "TOKEN_PRIVATE";
    case TOKEN_PUBLIC:  return "TOKEN_PUBLIC";
    case TOKEN_EXTERN:  return "TOKEN_EXTERN";

    case TOKEN_RETURN:  return "TOKEN_RETURN";
    case TOKEN_TRUE:    return "TOKEN_TRUE";
    case TOKEN_FALSE:   return "TOKEN_FALSE";
    case TOKEN_FUNC:    return "TOKEN_FUNC";
    case TOKEN_STRUCT:  return "TOKEN_STRUCT";
    case TOKEN_ENUM:    return "TOKEN_ENUM";
    case TOKEN_UNION:   return "TOKEN_UNION";

    case TOKEN_FOR:     return "TOKEN_FOR";
    case TOKEN_WHILE:   return "TOKEN_WHILE";
    case TOKEN_IF:      return "TOKEN_IF";
    case TOKEN_ELSE:    return "TOKEN_ELSE";

    // Types
    case TOKEN_VOID:    return "TOKEN_VOID";
    case TOKEN_BOOL:    return "TOKEN_BOOL";
    case TOKEN_BYTE:    return "TOKEN_BYTE";
    case TOKEN_I16:     return "TOKEN_I16";
    case TOKEN_I32:     return "TOKEN_I32";
    case TOKEN_I64:     return "TOKEN_I64";
    case TOKEN_F32:     return "TOKEN_F32";
    case TOKEN_F64:     return "TOKEN_F64";

    // Identifiers
    case TOKEN_IDENTIFER: return "TOKEN_IDENTIFER";

    // Literals
    case TOKEN_INTEGER_LITERAL: return "TOKEN_INTEGER_LITERAL";
    case TOKEN_FLOAT_LITERAL:   return "TOKEN_FLOAT_LITERAL";
    case TOKEN_STRING_LITERAL:  return "TOKEN_STRING_LITERAL";
    case TOKEN_CHAR_LITERAL:    return "TOKEN_CHAR_LITERAL";

    // Operators
    case TOKEN_PLUS:     return "TOKEN_PLUS";
    case TOKEN_MINUS:    return "TOKEN_MINUS";
    case TOKEN_STAR:     return "TOKEN_STAR";
    case TOKEN_SLASH:    return "TOKEN_SLASH";
    case TOKEN_EQUAL:    return "TOKEN_EQUAL";
    case TOKEN_ASSIGN:   return "TOKEN_ASSIGN";
    case TOKEN_AND:      return "TOKEN_AND";
    case TOKEN_OR:       return "TOKEN_OR";
    case TOKEN_AMPER:    return "TOKEN_AMPER";
    case TOKEN_MOD:      return "TOKEN_MOD";
    case TOKEN_LESS:     return "TOKEN_LESS";
    case TOKEN_GREATER:  return "TOKEN_GREATER";
    case TOKEN_LE:       return "TOKEN_LE";
    case TOKEN_GE:       return "TOKEN_GE";
    case TOKEN_NOTEQUAL: return "TOKEN_NOTEQUAL";


    // Punctuation / delimiters
    case TOKEN_LPAR:      return "TOKEN_LPAR";
    case TOKEN_RPAR:      return "TOKEN_RPAR";
    case TOKEN_LCBRACK:   return "TOKEN_LCBRACK";
    case TOKEN_RCBRACK:   return "TOKEN_RCBRACK";
    case TOKEN_LBRACK:    return "TOKEN_LBRACK";
    case TOKEN_RBRACK:    return "TOKEN_RBRACK";
    case TOKEN_COMMA:     return "TOKEN_COMMA";
    case TOKEN_DOT:       return "TOKEN_DOT";
    case TOKEN_SEMICOLON: return "TOKEN_SEMICOLON";
    case TOKEN_COLON: return "TOKEN_COLON";

    // Special
    case TOKEN_EOF:     return "TOKEN_EOF";
    case TOKEN_INVALID: return "TOKEN_INVALID";
  }

  return "UNKNOWN_TOKEN";
}

const char *ast_kind_to_string(AstKind kind)
{
    switch (kind) {
        // Declarations
        case AST_INVALID:          return "INVALID";
        case AST_PACKAGE:          return "PACKAGE";
        case AST_IMPORT:           return "IMPORT";

        case AST_FUNC_DECL:        return "FUNC_DECL";
        case AST_STRUCT_DECL:      return "STRUCT_DECL";
        case AST_ENUM_DECL:        return "ENUM_DECL";
        case AST_UNION_DECL:       return "UNION_DECL";

        case AST_VAR_DECL:         return "VAR_DECL";

        // Statements
        case AST_BLOCK:            return "BLOCK";
        case AST_RETURN:           return "RETURN";
        case AST_IF:               return "IF";
        case AST_WHILE:            return "WHILE";
        case AST_FOR:              return "FOR";
        case AST_EXPR_STMT:        return "EXPR_STMT";

        // Expressions
        case AST_INTEGER_LITERAL:  return "INTEGER_LITERAL";
        case AST_FLOAT_LITERAL:    return "FLOAT_LITERAL";
        case AST_STRING_LITERAL:   return "STRING_LITERAL";
        case AST_CHAR_LITERAL:     return "CHAR_LITERAL";
        case AST_IDENTIFER:        return "IDENTIFER";
        case AST_BOOL_LITERAL:     return "BOOL_LITERAL";

        case AST_BINARY:           return "BINARY";
        case AST_UNARY:            return "UNARY";
        case AST_ASSIGN:           return "ASSIGN";
        case AST_DECL:             return "DECL";
        case AST_CALL:             return "CALL";
        case AST_MEMBER:           return "MEMBER";
        case AST_INDEX:            return "INDEX";
        case AST_CAST:             return "CAST";
        case AST_COMPOUND_LITERAL: return "COMPOUND_LITERAL";

        // Types
        case AST_TYPE_VOID:        return "TYPE_VOID";
        case AST_TYPE_BOOL:        return "TYPE_BOOL";
        case AST_TYPE_BYTE:        return "TYPE_BYTE";
        case AST_TYPE_I16:         return "TYPE_I16";
        case AST_TYPE_I32:         return "TYPE_I32";
        case AST_TYPE_I64:         return "TYPE_I64";
        case AST_TYPE_F32:         return "TYPE_F32";
        case AST_TYPE_F64:         return "TYPE_F64";

        case AST_TYPE_NAME:        return "TYPE_NAME";
        case AST_TYPE_POINTER:     return "TYPE_POINTER";
        case AST_TYPE_ARRAY:       return "TYPE_ARRAY";

        default:
            return "UNKNOWN";
    }
}

const char *type_kind_name(TypeKind kind)
{
    switch (kind) {
        case TYPE_VOID:  return "void";
        case TYPE_BOOL:  return "bool";
        case TYPE_BYTE:  return "byte";
        case TYPE_I16:   return "i16";
        case TYPE_I32:   return "i32";
        case TYPE_I64:   return "i64";
        case TYPE_F32:   return "f32";
        case TYPE_F64:   return "f64";

        case TYPE_POINTER:  return "pointer";
        case TYPE_ARRAY:    return "array";
        case TYPE_FUNCTION: return "function";
        case TYPE_STRUCT:   return "struct";

        case TYPE_STRING:   return "string";

        default: return "unknown";
    }
}

const char *symbol_kind_name(SymbolKind kind)
{
    switch (kind) {
        case SYMBOL_VARIABLE:  return "variable";
        case SYMBOL_FUNCTION:  return "function";
        case SYMBOL_TYPE:      return "type";
        case SYMBOL_PARAMETER: return "parameter";
        case SYMBOL_FIELD:     return "field";
        default:               return "unknown";
    }
}

void log_span(SourceSpan span, const char* fmt, ...) {
  #ifndef SILENT
  va_list args;
  va_start(args, fmt);
  printf("%s:%d:%d: ", span.start.file, span.start.line, span.start.column);
  vprintf(fmt, args);
  va_end(args);
  #endif
}

int panic(const char *err) {
  printf("error: %s\n", err);
  exit(1);
}



void print_token(Token token) {
#ifndef SILENT
  printf("%s { '%s', { %s, %d:%d,} }\n", token_kind_to_string(token.kind),
         token.lexeme, token.span.start.file, token.span.start.column,
         token.span.end.column);
  #endif
}

void debug_log(const char *fmt, ...) {
    #ifndef SILENT
    va_list args;
    va_start(args, fmt);

    vprintf(fmt, args);

    va_end(args);
    #endif
}

char *read_file(const char *path, size_t *size)
{
    FILE *file = fopen(path, "rb");
    if (!file)
        return NULL;

    fseek(file, 0, SEEK_END);
    long file_size = ftell(file);
    rewind(file);

    if (file_size < 0) {
        fclose(file);
        return NULL;
    }

    char *data = malloc((size_t)file_size + 1);
    if (!data) {
        fclose(file);
        return NULL;
    }

    size_t bytes_read = fread(data, 1, (size_t)file_size, file);
    fclose(file);

    if (bytes_read != (size_t)file_size) {
        free(data);
        return NULL;
    }

    data[file_size] = '\0';

    if (size)
        *size = (size_t)file_size;

    return data;
}
