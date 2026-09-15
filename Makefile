CC = gcc

CFLAGS = -Wall -pedantic $(shell llvm-config --cflags)
LDFLAGS = $(shell llvm-config --ldflags)
LIBS = $(shell llvm-config --libs)

run: langer
	./langer

langer: ./src/main.c ./src/lexer.c ./src/utils.c ./include/sb.c ./src/parser.c ./src/llvm.c
	$(CC) $(CFLAGS) ./src/main.c ./src/lexer.c ./src/utils.c ./include/sb.c ./src/parser.c ./src/llvm.c  -o langer $(LDFLAGS) $(LIBS)

test:
	$(CC) -DSILENT -lrt -lm ./tests/tests.c ./src/parser.c ./src/lexer.c ./src/utils.c ./include/sb.c -o test &&./test

verbose:
	$(CC) -lrt -lm ./tests/tests.c ./src/parser.c ./src/lexer.c ./src/utils.c ./include/sb.c -o test &&./test


# install: langer
# 	ln -s $$PWD/langer /usr/local/bin/langer
# 	mkdir /usr/lib/langer
# 	ln -s $$PWD/std /usr/lib/langer/std

# uninstall:
# 	rm -rf /usr/local/bin/langer
# 	rm -rf /usr/lib/langer

