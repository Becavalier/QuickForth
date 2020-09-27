%macro sys_parse_int 0
    xor r8, r8
    xor r10, r10
%%start:
    mov r10b, [ep]
    cmp r10b, '0'
    jl %%complement
    sub r10b, '0'
    imul r8, 10
    add r8, r10
    inc ep
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

; %1 - branch: word.
; %2 - branch: number.
; %3 - branch: (invalid).
%macro sys_parse_word 3
    xor r8, r8
%%consume_space:
    mov r8b, [ep]
    cmp r8b, 0
    je %3
    cmp r8b, ' '
    jne %%consume_line_feed
    inc ep
    jmp %%consume_space
%%consume_line_feed:
    cmp r8b, `\n`
    jne %%validate_entry
    inc ep
    jmp %%consume_space
%%validate_entry:
    cmp r8, '-'
    jne %%validate_num
    inc ep
    mov r8b, [ep]
    mov rax, NEGATIVE_FLAG  ; indicate negative.
%%validate_num:
    cmp r8, '9'
    jg %%lookup_compensate
    cmp r8, '0'
    jge %2
%%lookup_compensate:
    cmp rax, NEGATIVE_FLAG
    jne %%lookup_word_main
    dec ep
%%lookup_word_main:
    mov r8, _nw_head
    push ep
%%word_forward:
    mov ep, [rsp]
    mov r8, [r8]  ; start looking. 
    cmp qword[r8], 0
    je %%word_invalid_clean
    mov r9, r8
    add r9, 8
%%word_loop:
    mov al, [ep]  ; input char;
    cmp byte[r9], 0 
    jne %%continue
    cmp al, `\n`
    je %%word_valid_clean
    cmp al, ' '
    je %%word_valid_clean
    jmp %%word_forward
%%continue:
    mov r10, r9
    inc r9
    inc ep
    sub al, [r10]  ; compare char;
    jz %%word_loop
    jmp %%word_forward
%%word_valid_clean:
    add rsp, 8
    jmp %1
%%word_invalid_clean:
    add rsp, 8
    jmp %3
%endmacro
