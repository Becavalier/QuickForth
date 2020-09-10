%macro sys_exit 0
xor rdi, rdi
mov rax, 60
syscall
%endmacro

%macro sys_print 2
lea rsi, %1
mov rdi, 1
mov rdx, %2
mov rax, 1
syscall
%endmacro

%macro sys_read_stdin 2
mov rsi, %1
mov rdi, 1
mov rdx, %2
mov rax, 0
syscall
%endmacro
