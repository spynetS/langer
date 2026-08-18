extern puts
extern printf
section .data
string0 db "it is %d", 0
section .text
global main
add:

mov [rbp-8], rdi
mov [rbp-16], rsi
mov rbx,[rbp-8]
mov r10,[rbp-16]
add rbx, r10
mov rax,rbx
ret
main:

mov r10, 1
mov rsi, r10
mov r11, 1
mov rdi, r11
push rbx
push r10
push r11
xor eax, eax
call add

pop r11
pop r10
pop rbx


mov qword [rbp-8], rax
mov r12,[rbp-8]
mov rsi, r12
lea rdi, [rel string0]
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
ret

xor eax, eax
ret