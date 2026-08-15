extern puts
section .data
data1 db "Hello World!" , 10
data0 db "Hello World!" , 10
section .text
global main
main:sub rsp, 8 
mov rdi, data1
call puts
xor eax, eax
add rsp, 8
ret
