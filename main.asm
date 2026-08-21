extern printf
extern malloc

section .data
string1 db "%d ", 0
string0 db "%d ", 0
section .text
global set

set:

push rbp
mov rbp, rsp
sub rsp, 16
mov [rbp-8], rdi
mov rbx, 0
mov qword [rbp-16], rbx
.L1:

sub rsp, 0
mov rbx,[rbp-16]
mov r10, [rbp-8]
mov r11,[rbp-16]
mov qword [r10+r11*8], rbx
mov rbx,[rbp-16]
mov r10, 1
add rbx, r10
mov qword [rbp-16], rbx
mov rbx,[rbp-16]
mov r10, 10
cmp rbx, r10
jle .L1
leave

ret

global main

main:

push rbp
mov rbp, rsp
sub rsp, 16
mov r12, 8
mov r13, 10
imul r12, r13
mov rdi, r12
push rbx
push r10
push r11
xor eax, eax
call malloc

pop r11
pop r10
pop rbx


mov qword [rbp-8], rax
mov r12,[rbp-8]
mov rdi, r12
push rbx
push r10
push r11
xor eax, eax
call set

pop r11
pop r10
pop rbx


mov r12, 0
mov qword [rbp-16], r12
.L2:

sub rsp, 0
mov r12, [rbp-8]
mov r13,[rbp-16]
mov r12, [r12+r13*8]
mov rsi, r12
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


mov r13,[rbp-16]
mov r14, 1
add r13, r14
mov qword [rbp-16], r13
mov r13,[rbp-16]
mov r14, 10
cmp r13, r14
jle .L2
mov r15, 0
mov rax,r15
leave

ret

ret


xor eax, eax
ret