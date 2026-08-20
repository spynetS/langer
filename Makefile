
main: main.o
	gcc -no-pie main.o -o main

main.o: main.asm
	nasm -f elf64 main.asm -o main.o

add.o: add.asm
	nasm -f elf64 add.asm -o add.o

main.asm: main.langer
	./langer ./main.langer

add.asm: add.langer
	./langer ./add.langer


program: main.o add.o 
	ld -dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc main.o add.o -o program

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
