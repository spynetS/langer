extern puts
extern printf
section .data
data3 db "Alfred here" , 0
data0 db "Hello World %s!" , 0
data2 db "Hello World %s!" , 0
data1 db "Alfred here" , 0
section .text
global main
main:lea rdi, [rel data2]
lea rdi, [rel data3]
xor eax, eax
call printf

xor eax, eax
ret