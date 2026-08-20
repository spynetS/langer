extern puts
extern printf
section .data
string1 db "IF", 0
string2 db "ELSE", 0
string0 db "Hej", 0
section .text
global main
age:

mov rbx, 22
mov rax,rbx
ret
print:

lea rdi, [rel string0]
push rbx
xor eax, eax
call puts

pop rbx


ret
main:

push rbx
xor eax, eax
call age

pop rbx


mov r10, 1
cmp rax, r10
jge .L1
lea rdi, [rel string2]
push rbx
push r10
xor eax, eax
call puts

pop r10
pop rbx


jmp .L2
.L1:
lea rdi, [rel string1]
push rbx
xor eax, eax
call puts

pop rbx


push rbx
xor eax, eax
call print

pop rbx



.L2:

mov r11, 0
mov rax,r11
ret

xor eax, eax
ret