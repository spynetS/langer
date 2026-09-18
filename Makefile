CC = gcc

CFLAGS = -Wall -pedantic $(shell llvm-config --cflags)
LDFLAGS = $(shell llvm-config --ldflags)
LIBS = $(shell llvm-config --libs)

COMPILER_FILES = $(wildcard ./src/*.c)
INCLUDE_FILES = $(wildcard ./include/*.c)

run: langer
	./langer

langer: $(COMPILER_FILES) ./src/main.c
	$(CC) $(CFLAGS) $(COMPILER_FILES) $(INCLUDE_FILES) -o langer $(LDFLAGS) $(LIBS)

test: test-bin
	./test

test-bin:
	$(CC) -DSILENT -lrt -lm ./tests/tests.c $(filter-out ./src/main.c, $(COMPILER_FILES)) $(INCLUDE_FILES) -o test $(LDFLAGS) $(LIBS) 

verbose-bin:
	$(CC) -lrt -lm ./tests/tests.c $(filter-out ./src/main.c, $(COMPILER_FILES)) $(INCLUDE_FILES) -o test $(LDFLAGS) $(LIBS)

verbose: verbose-bin
	./test

# install: langer
# 	ln -s $$PWD/langer /usr/local/bin/langer
# 	mkdir /usr/lib/langer
# 	ln -s $$PWD/std /usr/lib/langer/std

# uninstall:
# 	rm -rf /usr/local/bin/langer
# 	rm -rf /usr/lib/langer

