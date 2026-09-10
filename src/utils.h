#ifndef UTILS_H
#define UTILS_H

#include "lexer.h"
#include <stdio.h>

int panic(const char *err);
void print_token(Token token);

void debug_log(const char* fmt, ...);

char *read_file(const char *path, size_t *size);

#endif
