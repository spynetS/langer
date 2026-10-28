#ifndef UTILS_H
#define UTILS_H

#include "lexer.h"
#include "symbol_table.h"
#include "ast.h"
#include <stdio.h>

#define BG_BLACK  "\x1b[40m"
#define BG_RED    "\x1b[41m"
#define BG_GREEN  "\x1b[42m"
#define BG_YELLOW "\x1b[43m"
#define BG_BLUE   "\x1b[44m"
#define BG_PURPLE "\x1b[45m"
#define BG_CYAN   "\x1b[46m" 
#define BG_WHITE  "\x1b[47m"


#define BLACK  "\x1b[30m"
#define RED    "\x1b[31m"
#define GREEN  "\x1b[32m"
#define YELLOW "\x1b[33m"
#define BLUE   "\x1b[34m"
#define PURPLE "\x1b[35m"
#define CYAN   "\x1b[36m" 
#define WHITE  "\x1b[37m"
#define BG     "██"

#define RESET "\x1b[0m"
#define BG_RESET "\x1b[10m"


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
