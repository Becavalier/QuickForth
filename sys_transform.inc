%macro sys_parse_int 1
    push rax
    xor rax, rax
    xor r8, r8
    xor r10, r10
%%start:
    mov r10b, [%1 + rax]
    cmp r10b, '0'
    jl %%complement
    sub r10b, '0'
    imul r8, 10
    add r8, r10
    inc rax
    jmp %%start
%%complement:
    pop rax
    cmp rax, -1
    jne %%end
    not r8
    or r8, 1 << 15
    inc r8
%%end:
    xor rax, rax
    movsx rax, r8d
    ;mov r8, 0xffffffff00000000
    ;or rax, r8
%endmacro
