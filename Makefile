
main: main.o
	ld main.o -o main
main.o: main.asm compiler
	nasm -f elf64 main.asm -o main.o

compiler: main.odin codegen.odin lexer.odin parser.odin
	odin build . -out:compiler
	./compiler

cc:
	./compiler
	nasm -f elf64 main.asm -o main.o
	ld main.o -o main
	./main
run: main
	./main
	echo $?
