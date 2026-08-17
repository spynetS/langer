extern puts
extern printf
section .data
string1 db "alfred", 0
string0 db "Hello world im %s and im %d years old", 0
age: dq 0
section .text
global main
main:

mov rbx, 20
mov r10, 1
add rbx, r10
mov qword [rel age], rbx
lea rdi, [rel string0]
lea rsi, [rel string1]
mov r10, [rel age]
mov r11, 1
add r10, r11
mov rdx, r10
xor eax, eax
call printf

xor eax, eax
ret