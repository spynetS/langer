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

char lexer_next(Lexer *l) {
  if (l->pos >= l->bytes_length)
    return '\0';

  return l->bytes[l->pos+1];
}

char lexer_advance(Lexer *l) {
  if (l->pos >= l->bytes_length)
    return '\0';

  if (lexer_peek(l) == '\n') {
    l->line += 1;
    l->column = 1;
  } else {
    l->column += 1;
  }
  int p = l->pos;
  l->pos += 1;
  return l->bytes[p];
}

Token token_create(Lexer* l, TokenKind kind) {
  Token token = {0};
  token.span.start = lexer_create_pos(l);
  token.kind = kind;
  return token;
}

char lexer_skip_whitespace(Lexer *l) {
  while (lexer_peek(l) == ' ' ||
         lexer_peek(l) == '\n' ||
         lexer_peek(l) == '\t' ||
         lexer_peek(l) == '\r') {
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
  size_t counter = 0;
  while (lexer_peek(l) != '"') {
    // we encoutner error while lexing string
    if (lexer_peek(l) == '\0' || counter++ > MAX_TOKENS) {
      log_span((SourceSpan){start, {0}} ,"error: unterminated string literal\n");
      Token token = {0};
      token.lexeme = sb_concat(sb);
      token.kind = TOKEN_INVALID;

      sb_free(sb);
      return token;
    }
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
  Token t = token_create(lexer, kind);
  t.lexeme = malloc(sizeof(char)*2);
  t.lexeme[0] = lexer_peek(lexer);
  t.lexeme[1] = 0;
  SourcePos start = lexer_create_pos(lexer);
  lexer_advance(lexer);
  SourcePos end = lexer_create_pos(lexer);
  t.span = (SourceSpan){start,end};
  return t;
}

Token lex_char(Lexer *l) {
  lexer_advance(l);
  SourcePos start = lexer_create_pos(l);
  Token token = {0};
  token.kind = TOKEN_CHAR_LITERAL;
  char c = lexer_advance(l);
  token.lexeme = malloc(sizeof(char)*4);
  sprintf(token.lexeme, "'%c'", c);
  token.span = (SourceSpan){start, lexer_create_pos(l)};

  if (lexer_advance(l) != '\'') {
    log_span((SourceSpan){lexer_create_pos(l), lexer_create_pos(l)},"error: untermineted char\n");
    return token_create(l, TOKEN_INVALID);
  }

  return token;
}

Token lex_two(Lexer *lexer, char a, char b, TokenKind kind) {
  if (lexer_peek(lexer) == a && lexer_next(lexer) == b) {
      lexer_advance(lexer);
      lexer_advance(lexer);
      return token_create(lexer, kind);
  }
  return token_create(lexer,TOKEN_INVALID);
}

void lex_inline_comment(Lexer *lexer) {
  while (lexer_peek(lexer) != '\n') {
    lexer_advance(lexer);
  }
}
void lex_comment(Lexer *lexer) {
  lexer_advance(lexer);
  lexer_advance(lexer);

  while (lexer_peek(lexer) != '*' && lexer_next(lexer) != '/') {
    lexer_advance(lexer);
  }
  lexer_advance(lexer);
  lexer_advance(lexer);
}

Token lex(Lexer *lexer) {

  char c = lexer_skip_whitespace(lexer);

  Token token = {0};
  token.kind = TOKEN_EOF;

  //debug_log("%c\n", c);
  if (c == '\0')
    return token;

  if      ( (token = lex_two(lexer, '&', '&', TOKEN_AND)).kind != TOKEN_INVALID){}
  else if ( (token = lex_two(lexer, '|', '|', TOKEN_OR)).kind != TOKEN_INVALID){}
  else if ( (token = lex_two(lexer, '=', '=', TOKEN_EQUAL)).kind != TOKEN_INVALID){}
  else if ( (token = lex_two(lexer, '<','=', TOKEN_LE)).kind != TOKEN_INVALID){}
  else if ( (token = lex_two(lexer, '>','=', TOKEN_GE)).kind != TOKEN_INVALID){}
  else if ( (token = lex_two(lexer, '!','=', TOKEN_NOTEQUAL)).kind != TOKEN_INVALID){}
  else if ( c == '/' && lexer_next(lexer) == '/' ) {
    lex_inline_comment(lexer);
    return lex(lexer);
  }
  else if ( c == '/' && lexer_next(lexer) == '*' ) {
    lex_comment(lexer);
    return lex(lexer);
  }
  else if (c == '\'')       token = lex_char(lexer);
  else if (is_char(c)) token = lex_identifer(lexer);
  else if (is_digit(c)) token = lex_number_literal(lexer);
  else if (c == '"')    token = lex_string_literal(lexer);
  else {
    switch (c) {
    case '=': token = char_token(lexer, TOKEN_ASSIGN);    break;
    case '+': token = char_token(lexer, TOKEN_PLUS);      break;
    case '-': token = char_token(lexer, TOKEN_MINUS);     break;
    case '*': token = char_token(lexer, TOKEN_STAR);      break;
    case '/': token = char_token(lexer, TOKEN_SLASH);     break;
    case '&': token = char_token(lexer, TOKEN_AMPER);     break;
    case '%': token = char_token(lexer, TOKEN_MOD);       break;
    case '<': token = char_token(lexer, TOKEN_LESS);      break;
    case '>': token = char_token(lexer, TOKEN_GREATER);   break;

    case '(': token = char_token(lexer, TOKEN_LPAR);      break;
    case ')': token = char_token(lexer, TOKEN_RPAR);      break;
    case '{': token = char_token(lexer, TOKEN_LCBRACK);   break;
    case '}': token = char_token(lexer, TOKEN_RCBRACK);   break;
    case '[': token = char_token(lexer, TOKEN_LBRACK);    break;
    case ']': token = char_token(lexer, TOKEN_RBRACK);    break;

    case ',': token = char_token(lexer, TOKEN_COMMA);     break;
    case '.': token = char_token(lexer, TOKEN_DOT);       break;
    case ';': token = char_token(lexer, TOKEN_SEMICOLON); break;
    case ':': token = char_token(lexer, TOKEN_COLON);          break;
    case '\0':token = char_token(lexer, TOKEN_EOF);       break;

    default:
      token = char_token(lexer, TOKEN_INVALID);
      break;
    }
  }
    
  return token;
}

int lexer_tokenize(Lexer *lexer, Token **result) {
  lexer->line = 1;
  lexer->column = 1;
  while (true) {
      Token token = lex(lexer);
      
      if (token.kind == TOKEN_EOF || token.kind == TOKEN_INVALID)
        break;
      #ifndef SILENT
      print_token(token);
      #endif
      arrput(*result, token);
  }
  return 0;
}

void free_token(Token *token) {
  if (token == NULL) return;
  if (token->lexeme != NULL)
    free(token->lexeme);
}
