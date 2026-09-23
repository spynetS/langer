#ifndef UTILS_H
#define UTILS_H

#include "lexer.h"
#include "symbol_table.h"
#include "ast.h"
#include <stdio.h>

int panic(const char *err);
void print_token(Token token);

void log_span(SourceSpan span, const char* fmt, ...);

void debug_log(const char* fmt, ...);

char *read_file(const char *path, size_t *size);
const char *token_kind_to_string (TokenKind kind);
const char *ast_kind_to_string   (AstKind kind);
const char *symbol_kind_name(SymbolKind kind);
const char *type_kind_name(TypeKind kind);

#endif
