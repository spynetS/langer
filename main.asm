extern puts
extern printf
section .data
string0 db "Hello world im %d years old", 0
a: dq 0
age: dq 0
section .text
global main
add:

mov rbx, 10
mov qword [rel a], rbx
mov r10, [rel a]
mov r11, 1
add r10, r11
mov rax,r10
ret
main:

push rbx
push r10
xor eax, eax
call add

pop r10
pop rbx


mov qword [rel age], rax
lea rdi, [rel string0]
mov r11, [rel age]
push rbx
push r10
push r11
xor eax, eax
call add

pop r11
pop r10
pop rbx


add r11, rax
mov rsi, r11
push rbx
push r10
push r11
xor eax, eax
call printf

pop r11
pop r10
pop rbx


mov r12, 0
mov rax,r12
ret

xor eax, eax
ret