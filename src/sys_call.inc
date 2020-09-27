%macro syscall_exit 0
xor rdi, rdi
mov rax, 60
syscall
%endmacro


%macro syscall_write 4
%ifidn %4, SYSCALL_KEEP_REG_FLAG
push rsi
push rdi
%endif
mov rdi, %1
lea rsi, %2
mov rdx, %3
mov rax, 1
syscall
%ifidn %4, SYSCALL_KEEP_REG_FLAG
pop rdi
pop rsi
%endif
%endmacro

%macro syscall_read 4
%ifidn %4, SYSCALL_KEEP_REG_FLAG
push rsi
push rdi
%endif
mov rdi, %1
mov rsi, %2
mov rdx, %3
mov rax, 0
syscall
%ifidn %4, SYSCALL_KEEP_REG_FLAG
pop rdi
pop rsi
%endif
%endmacro

%macro syscall_open 4
%ifidn %4, SYSCALL_KEEP_REG_FLAG
push rsi
push rdi
%endif
mov rdi, %1
mov rsi, %2
mov rdx, %3
mov rax, 2
syscall
%ifidn %4, SYSCALL_KEEP_REG_FLAG
pop rdi
pop rsi
%endif
%endmacro
