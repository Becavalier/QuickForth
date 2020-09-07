%macro sys_parse_int 1
    xor rax, rax
    xor r8, r8
    xor r9, r9
%%start:
    mov r9b, [%1 + r8]
    cmp r9b, '0'
    jl %%end
    sub r9b, '0'
    imul rax, 10
    add rax, r9
    inc r8
    jmp %%start
%%end:
%endmacro
