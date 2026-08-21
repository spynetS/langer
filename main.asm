extern printf
extern malloc

section .data
string1 db "%d", 0
string0 db "%d", 0
section .text
global main

main:

push rbp
mov rbp, rsp
sub rsp, 8
mov rbx, 10
mov rdi, rbx
xor eax, eax
call malloc



mov qword [rbp-8], rax
mov rbx, 0
mov r10, [rbp-8]
mov r11, 0
mov qword [r10+r11*8], rbx
mov rbx,[rbp-8]
mov rsi, rbx
lea rbx, [rel string0]
lea rdi, [rel string1]
push rbx
push r11
xor eax, eax
call printf

pop r11


mov r10, 0
mov rax,r10
leave

ret

ret


xor eax, eax
ret