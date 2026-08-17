extern puts
extern printf
section .data
data1 db "Hello World im %d years old!" , 0
data0 db "Hello World im %d years old!" , 0
section .text
global main
main:lea rdi, [rel data1]
mov rsi, 22
xor eax, eax
call printf

xor eax, eax
ret