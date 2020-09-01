; (BOTTOM GUARD).
%macro sys_parse_int_bg 1
    mov r8, 0
    xor rax, rax
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
