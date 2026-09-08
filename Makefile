CC = odin


langer: ./src/ast.odin ./src/llvm_code_gen.odin	./src/messages.odin ./src/symbol_table.odin ./src/lexer.odin ./src/main.odin ./src/parser.odin ./src/type_checker.odin
	$(CC) build src -out=langer

install: langer
	ln -s $$PWD/langer /usr/local/bin/langer
	mkdir /usr/lib/langer
	ln -s $$PWD/std /usr/lib/langer/std

uninstall:
	rm -rf /usr/local/bin/langer
	rm -rf /usr/lib/langer

