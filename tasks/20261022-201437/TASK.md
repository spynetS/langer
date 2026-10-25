# make so lexer/parser uses real bytes in string

- STATUS: CLOSED
- PRIORITY: 200
- TAGS:

Currently the string is parsed as a string so escape chars
are treated as the chars. Lex it so escape chars are treated
as the bytes they represent.

fixed it in llvm.c instead
