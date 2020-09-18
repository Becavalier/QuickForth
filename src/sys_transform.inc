%macro sys_parse_int 1
    xor r8, r8
    xor r10, r10
%%start:
    mov r10b, [%1]
    cmp r10b, '0'
    jl %%complement
    sub r10b, '0'
    imul r8, 10
    add r8, r10
    inc %1
    jmp %%start
%%complement:
    cmp rax, NEGATIVE_FLAG
    jne %%end
    not r8
    or r8d, 1 << 31
    inc r8
%%end:
    movsx rax, r8d
%endmacro

; %1 - input buffer;
; %2 - word evaluation branch;
; %3 - number evaluation branch;
; %4 - invalid branch;
%macro sys_parse_word 4
    lea r9, [%1]
    xor r8, r8
    mov r8b, [r9]
    cmp r8, '-'
    jne %%validate_num
    inc r9
    mov r8b, [r9]
    mov rax, NEGATIVE_FLAG  ; indicate negative.
%%validate_num:
    cmp r8, '9'
    jg %%lookup_word
    cmp r8, '0'
    jge %3
%%lookup_word:
    cmp rax, NEGATIVE_FLAG
    je %4
    mov r8, _nw_head
%%word_forward:
    mov rcx, -1
    mov r8, [r8]  ; start looking. 
    cmp qword[r8], 0
    je %4
    mov r10, r8
    add r10, 8
%%word_loop:
    inc rcx
    mov bpl, [r9 + rcx]  ; input char;
    cmp byte[r10 + rcx], 0
    jne %%continue
    cmp bpl, `\n`
    je %2
    cmp bpl, ' '
    je %2
%%continue:
    sub bpl, [r10 + rcx]  ; comparing char;
    jz %%word_loop
    jmp %%word_forward
%endmacro