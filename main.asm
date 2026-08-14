global _start
section .text
_start:
push 2
push 2
pop rbx
pop rax
add rax, rbx
push rax
push 1
push 1
pop rbx
pop rax
add rax, rbx
push rax
pop rbx
pop rax
add rax, rbx
push rax
mov edi, eax
mov eax, 60
syscall