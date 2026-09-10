#ifndef LEXER_H
#define LEXER_H

#include <stdio.h>

typedef enum TokenKind {
  // keywords
  TOKEN_PACKAGE,
  TOKEN_IMPORT,
  TOKEN_PRIVATE,
  TOKEN_PUBLIC,
  TOKEN_EXTERN,

  TOKEN_RETURN,
  TOKEN_TRUE,
  TOKEN_FALSE,
  TOKEN_FUNC,
  TOKEN_STRUCT,
  TOKEN_ENUM,
  TOKEN_UNION,

  TOKEN_FOR,
  TOKEN_WHILE,
  TOKEN_IF,
  TOKEN_ELSE,

  // types (keyowrd)

  TOKEN_VOID,
  TOKEN_BOOL,
  TOKEN_BYTE,
  TOKEN_I16,
  TOKEN_I32,
  TOKEN_I64,
  TOKEN_F32,
  TOKEN_F64,

  // IDENTIFERS
  TOKEN_IDENTIFER,

  //LITERALS
  TOKEN_INTEGER_LITERAL,
  TOKEN_FLOAT_LITERAL,
  TOKEN_STRING_LITERAL,
  TOKEN_CHAR_LITERAL,
 
  // OPERATORS
  TOKEN_PLUS,
  TOKEN_MINUS,
  TOKEN_STAR,
  TOKEN_SLASH,
  TOKEN_EQUAL, // ==
  TOKEN_ASSIGN, // =
  TOKEN_AMPER,
  TOKEN_AND,
  TOKEN_OR,
  TOKEN_MOD,

  //Punctuation / delimiters
  TOKEN_LPAR, // (
  TOKEN_RPAR, // )
  TOKEN_LCBRACK, // {
  TOKEN_RCBRACK, // }
  TOKEN_LBRACK, // [
  TOKEN_RBRACK,  // ]
  TOKEN_COMMA,
  TOKEN_DOT,
  TOKEN_SEMICOLON,
  TOKEN_COLON,

  // Special tokens
  TOKEN_EOF,
  TOKEN_INVALID
} TokenKind;

typedef struct {
  const char *text;
  TokenKind kind;
} Keyword;

static const Keyword keywords[] = {
  // Keywords
  { "package", TOKEN_PACKAGE },
  { "import",  TOKEN_IMPORT },
  { "private", TOKEN_PRIVATE },
  { "public",  TOKEN_PUBLIC },
  { "extern",  TOKEN_EXTERN },

  { "return",  TOKEN_RETURN },
  { "true",    TOKEN_TRUE },
  { "false",   TOKEN_FALSE },
  { "func",    TOKEN_FUNC },
  { "struct",  TOKEN_STRUCT },
  { "enum",    TOKEN_ENUM },
  { "union",   TOKEN_UNION },

  { "for",     TOKEN_FOR },
  { "while",   TOKEN_WHILE },
  { "if",      TOKEN_IF },
  { "else",    TOKEN_ELSE },

  // Types
  { "void",    TOKEN_VOID },
  { "bool",    TOKEN_BOOL },
  { "byte",    TOKEN_BYTE },
  { "char",    TOKEN_BYTE },
  { "int",     TOKEN_I32 },
  { "float",   TOKEN_F32 },
  { "double",  TOKEN_F64 },
  { "i16",     TOKEN_I16 },
  { "i32",     TOKEN_I32 },
  { "i64",     TOKEN_I64 },
  { "f32",     TOKEN_F32 },
  { "f64",     TOKEN_F64 },
};

typedef struct {
  int line;
  int column;
  const char* file;
} SourcePos;

typedef struct {
  SourcePos start;
  SourcePos end;
} SourceSpan;

typedef struct token {
  TokenKind kind;
  char* lexeme;
  SourceSpan span;
} Token;


typedef struct lexer {
  int line;
  int column;
  char* file;

  int pos;
  
  char* bytes;
  size_t bytes_length;
} Lexer;



char lexer_skip_whitespace(Lexer *l);
char lexer_peek(Lexer *l);
char lexer_advance(Lexer *l);

// Returns 0 for success
int lexer_tokenize(Lexer*, Token** result);
Token lex(Lexer *l);

// will allocate for lexeme
Token lex_word(Lexer*);

void free_token(Token *token);


#endif
