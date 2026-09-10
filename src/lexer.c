#include "lexer.h"
#include "utils.h"
#include "stb_ds.h"
#include "sb.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

#define MAX_TOKENS 1000



SourcePos lexer_create_pos(Lexer *l) {
  SourcePos pos;
  pos.column = l->column;
  pos.line   = l->line;
  pos.file   = l->file;
  return pos;
}


char lexer_peek(Lexer *l) {
  return l->bytes[l->pos];
}

char lexer_advance(Lexer *l) {
  if ( l->bytes_length >= l->pos + 1 ) {

    if (lexer_peek(l) == '\n') {
      l->line += 1;
      l->column = 1;
    } else {
      l->column += 1;
    }
    

    return l->bytes[l->pos++];
  }
  return l->bytes[l->pos];
}

char lexer_skip_whitespace(Lexer *l) {
  while (lexer_peek(l) == ' ' ||
         lexer_peek(l) == '\n' ||
         lexer_peek(l) == '\t' ||
         lexer_peek(l) == '\r' ||
         lexer_peek(l) == 0) {
    lexer_advance(l);
  }
  return lexer_peek(l);
}

bool is_char(char a) {
  return (65 <= (int)a && (int)a <= 90) || (97 <= (int)a && (int)a <= 122);
}

bool is_digit(char a) {
  switch (a) {
  case '0': return true;
  case '1': return true;
  case '2': return true;
  case '3': return true;
  case '4': return true;
  case '5': return true;
  case '6': return true;
  case '7': return true;
  case '8': return true;
  case '9': return true;
      }
  return false;
}

TokenKind keyword_kind(const char *text) {
  for (size_t i = 0; i < sizeof(keywords) / sizeof(keywords[0]); i++) {
    if (strcmp(text, keywords[i].text) == 0)
      return keywords[i].kind;
  }
  return TOKEN_IDENTIFER;
}

Token lex_identifer(Lexer *l) {
  StringBuilder *sb = sb_create();
  SourcePos start = lexer_create_pos(l);
  sb_appendf(sb, "%c", lexer_advance(l));
  // if it is a char or _ or a digit we continue
  while (is_char(lexer_peek(l)) ||
         lexer_peek(l) == '_' ||
         is_digit(lexer_peek(l)) ) {
    sb_appendf(sb, "%c", lexer_advance(l));
  }
  SourcePos end = lexer_create_pos(l);

  char *lexeme = sb_concat(sb);
  TokenKind kind = keyword_kind(lexeme);

  
  Token token = {
    kind,
    lexeme,
    {
      start,
      end
    }
  };
  sb_free(sb);
  return token;
}

Token lex_string_literal(Lexer *l) {
  StringBuilder *sb = sb_create();
  SourcePos start = lexer_create_pos(l);
  sb_appendf(sb, "%c", lexer_advance(l));
  // if it is a char or _ or a digit we continue
  while (lexer_peek(l) != '"') {
    sb_appendf(sb, "%c", lexer_advance(l));
  }
  SourcePos end = lexer_create_pos(l);
  sb_appendf(sb, "%c", lexer_advance(l));
  Token token = {
    TOKEN_STRING_LITERAL,
    sb_concat(sb),
    {
      start,
      end
    }
  };
  sb_free(sb);
  return token;
}


//123        → integer literal
//123.0      → floating-point literal
//123e5      → floating-point literal
//123.0f     → float literal
//123.0d     → double literal
Token lex_number_literal(Lexer *l) {
  StringBuilder *sb = sb_create();
  SourcePos start = lexer_create_pos(l);
  
  sb_appendf(sb, "%c", lexer_advance(l));
  bool is_float = false;
  // if it is a char or _ or a digit we continue
  while (is_digit(lexer_peek(l)) ||
         lexer_peek(l) == '.') {

    if (!is_float && lexer_peek(l) == '.')
      is_float = true;
        
    sb_appendf(sb, "%c", lexer_advance(l));
  }
  SourcePos end = lexer_create_pos(l);
  Token token = {
    is_float ? TOKEN_FLOAT_LITERAL :TOKEN_INTEGER_LITERAL,
    sb_concat(sb),
    {
      start,
      end
    }
  };

  sb_free(sb);
  return token;
}

Token char_token(Lexer *lexer, TokenKind kind) {
  Token t;
  t.kind = kind;
  t.lexeme = malloc(sizeof(char)*2);
  t.lexeme[0] = lexer_peek(lexer);
  t.lexeme[1] = 0;
  SourcePos start = lexer_create_pos(lexer);
  lexer_advance(lexer);
  SourcePos end = lexer_create_pos(lexer);
  t.span = (SourceSpan){start,end};
  return t;
}

Token lex(Lexer *lexer) {

  char c = lexer_skip_whitespace(lexer);

  Token token;
  token.kind = TOKEN_EOF;

  debug_log("%c\n", c);

  if (is_char(c))       token = lex_identifer(lexer);
  else if (is_digit(c)) token = lex_number_literal(lexer);
  else if (c == '"')       token = lex_string_literal(lexer);
  else {
    switch (c) {
    case '=': token = char_token(lexer, TOKEN_ASSIGN);    break;
    case '+': token = char_token(lexer, TOKEN_PLUS);      break;
    case '-': token = char_token(lexer, TOKEN_MINUS);     break;
    case '*': token = char_token(lexer, TOKEN_STAR);      break;
    case '/': token = char_token(lexer, TOKEN_SLASH);     break;
    case '&': token = char_token(lexer, TOKEN_AND);       break;
    case '|': token = char_token(lexer, TOKEN_OR);        break;

    case '(': token = char_token(lexer, TOKEN_LPAR);      break;
    case ')': token = char_token(lexer, TOKEN_RPAR);      break;
    case '{': token = char_token(lexer, TOKEN_LCBRACK);   break;
    case '}': token = char_token(lexer, TOKEN_RCBRACK);   break;
    case '[': token = char_token(lexer, TOKEN_LBRACK);    break;
    case ']': token = char_token(lexer, TOKEN_RBRACK);    break;

    case ',': token = char_token(lexer, TOKEN_COMMA);     break;
    case '.': token = char_token(lexer, TOKEN_DOT);       break;
    case ';': token = char_token(lexer, TOKEN_SEMICOLON); break;
    case ':': token = char_token(lexer, TOKEN_COLON);         break;

    default:
      token = char_token(lexer, TOKEN_INVALID);
      break;
    }
  }
    
  return token;
}

int tokenize(Lexer *lexer, Token **result) {
  while (lexer->pos < lexer->bytes_length-1) {
      Token token = lex(lexer);
      print_token(token);
      
      if (token.kind == TOKEN_EOF || token.kind == TOKEN_INVALID)
        break;
      arrput(*result, token);
  }
  return 0;
}

void free_token(Token *token) {
  if (token == NULL) return;
  if (token->lexeme != NULL)
    free(token->lexeme);
}
