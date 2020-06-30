%macro sys_exit 0
xor rdi, rdi
mov rax, 60
syscall
%endmacro

%macro sys_print 2
lea rsi, %1
mov rdi, 1
mov rdx, 1
mov rax, %2
syscall
%endmacro
