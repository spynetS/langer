CC = gcc -Wall -pedantic

run: langer
	./langer

langer: ./src/main.c ./src/lexer.c ./src/utils.c ./src/sb.c
	$(CC) ./src/main.c ./src/lexer.c ./src/utils.c ./src/sb.c -o langer

# install: langer
# 	ln -s $$PWD/langer /usr/local/bin/langer
# 	mkdir /usr/lib/langer
# 	ln -s $$PWD/std /usr/lib/langer/std

# uninstall:
# 	rm -rf /usr/local/bin/langer
# 	rm -rf /usr/lib/langer

