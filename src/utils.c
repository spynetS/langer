#include "lexer.h"
#include <stdio.h>
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
    case TOKEN_INT:     return "TOKEN_INT";
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
    case TOKEN_PLUS:   return "TOKEN_PLUS";
    case TOKEN_MINUS:  return "TOKEN_MINUS";
    case TOKEN_STAR:   return "TOKEN_STAR";
    case TOKEN_SLASH:  return "TOKEN_SLASH";
    case TOKEN_EQUAL:  return "TOKEN_EQUAL";
    case TOKEN_ASSIGN: return "TOKEN_ASSIGN";
    case TOKEN_AND:    return "TOKEN_AND";
    case TOKEN_OR:     return "TOKEN_OR";

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

void log_span(SourceSpan span, const char* fmt, ...) {
  va_list args;
  va_start(args, fmt);
  printf("%s:%d:%d: ", span.start.file, span.start.line, span.start.column);
  vprintf(fmt, args);

  va_end(args);
}

int panic(const char *err) {
  printf("error: %s\n", err);
  exit(1);
}



void print_token(Token token) {
  printf("%s { '%s', { %s, %d:%d,} }\n", token_kind_to_string(token.kind), token.lexeme, token.span.start.file,  token.span.start.column,token.span.end.column);
}

void debug_log(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);

    vprintf(fmt, args);

    va_end(args);
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
