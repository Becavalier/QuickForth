%macro syscall_exit 0
xor rdi, rdi
mov rax, 60
syscall
%endmacro

%macro syscall_write 3
push rsi
push rdi
lea rsi, %2
mov rdi, %1
mov rdx, %3
mov rax, 1
syscall
pop rdi
pop rsi
%endmacro

%macro syscall_read 3
push rsi
push rdi
mov rsi, %2
mov rdi, %1
mov rdx, %3
mov rax, 0
syscall
pop rdi
pop rsi
%endmacro
