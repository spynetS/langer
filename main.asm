extern printf
extern add

section .data
string0 db "age = %d", 0
string1 db "age = %d", 0
section .text
global main

main:

push rbp
mov rbp, rsp
mov rbx, 5
mov rsi, rbx
mov r10, 10
mov rdi, r10
push rbx
push r10
xor eax, eax
call add

pop r10
pop rbx


mov qword [rbp-8], rax
mov r11,[rbp-8]
mov rsi, r11
lea r12, [rel string0]
lea rdi, [rel string1]
push rbx
push r10
push r11
push r12
xor eax, eax
call printf

pop r12
pop r11
pop r10
pop rbx


mov r13, 0
mov rax,r13
pop rbp

ret


xor eax, eax
ret