%include 'sys_call.inc'
%include 'sys_transform.inc'

; macros (%rcx and %r11 could be modified by syscall).
%define rstack r13
%define tstack rbx
%define pc r15
%define w r14
%define o_rsp r12

%define ascii_digits_offset 0x30
%define codes_arrow_sign_idx 0x10
%define codes_arrow_sign_len 2
%define codes_wrap_ctl_idx 0x12
%define codes_wrap_ctl_len 2
%define codes_invalid_txt_idx 0x14
%define codes_invalid_txt_len 11
%define codes_negative_sign_idx 0x1f

section .data
codes:
    db `0123456789ABCDEF> \n\r(invalid)\n\r-`  ; char symbols.

section .bss
resb 1024
tstack_start:
resb 1024  ; high addr.
rstack_start:
input_buf: resb 1024

global _start
section .text

main_stub:
    dq xt_read_word
    dq xt_eval_word
    dq xt_print_top_stack
    dq xt_exit

repl_stub:
    dq xt_read_word
    dq xt_eval_word
    dq xt_repl_reset
    dq xt_exit

; DICTIONARY (WORDS).
nw_docol:
    dq 0
    db 'docol', 0
    db 0
xt_docol:
    sub rstack, 8
    mov [rstack], pc
    add w, 8
    mov pc, w
    jmp next

; return.
nw_ret:
    dq nw_docol
    db 'ret', 0
    db 0
xt_ret:
    dq impl_ret

nw_plus:
    dq nw_ret
    db '+', 0
    db 0
xt_plus:
    dq impl_plus

nw_sub:
    dq nw_plus
    db '-', 0
    db 0
xt_sub:
    dq impl_sub

nw_mul:
    dq nw_sub
    db '*', 0
    db 0
xt_mul:
    dq impl_mul

nw_div:
    dq nw_mul
    db '/', 0
    db 0
xt_div:
    dq impl_div

; duplicate;
nw_dup:
    dq nw_div
    db 'dup', 0
    db 0
xt_dup:
    dq impl_dup

nw_print_top_stack:
    dq nw_dup
    db 'print_top_stack', 0
    db 0
xt_print_top_stack:
    dq impl_print_top_stack

nw_exit:
    dq nw_print_top_stack
    db 'exit', 0
    db 0
xt_exit:
    dq impl_exit

; double;
nw_dbl:
    dq nw_exit
    db 'dbl', 0
    db 0
xt_dbl:
    dq xt_docol
    dq xt_dup
    dq xt_plus
    dq xt_ret

; drop;
nw_drop:
    dq nw_dbl
    db 'drop', 0
    db 0
xt_drop:
    dq impl_drop

; swap;
nw_swap:
    dq nw_drop
    db 'swap', 0
    db 0
xt_swap:
    dq impl_swap

; rotate;
nw_rot:
    dq nw_swap
    db 'rot', 0
    db 0
xt_rot:
    dq impl_rot

_nw_head:
    dq nw_rot

; PRIVATE WORDS.
xt_repl_reset:
    dq impl_repl_reset

xt_init:
    dq impl_init

xt_read_word:
    dq impl_read_word

xt_eval_word:
    dq impl_eval_word

; IMPLEMENTATIONS.
impl_rot:  ; top -> bottom (left rotate).
    xor r8, r8
.start:
    lea r9, [rsp + 8]
    cmp o_rsp, r9
    jle .last
    mov r10, [rsp]
    sub tstack, 8
    mov [tstack], r10
    add rsp, 8
    inc r8
    jmp .start
.last:
    pop r9
.loop:
    cmp r8, 0
    je .over
    push qword[tstack]
    add tstack, 8
    dec r8
    jmp .loop
.over:
    push r9
.end:
    jmp next

impl_swap:
    mov r8, o_rsp
    sub r8, rsp
    cmp r8, 0x10 ; > 2.
    jl .end
    pop r8
    pop r9
    push r8
    push r9
.end:
    jmp next

impl_drop:
    cmp o_rsp, rsp
    je .end
    add rsp, 8
.end:
    jmp next

impl_repl_reset:
    mov pc, repl_stub
    jmp next

impl_eval_word:
    ; deal with primitives (number).
    xor rax, rax
    xor r8, r8
    lea r9, [input_buf]
    mov r8b, [r9]
    cmp r8, '-'
    jne .validate_num
    cmp byte[r9 + 1], 0xa
    je .lookup_word
    inc r9
    mov r8b, [r9]
    mov rax, -1  ; indicate negative.
.validate_num:
    cmp r8, '9'
    jg .lookup_word
    cmp r8, '0'
    jge .num_parse
.lookup_word:
    mov r8, _nw_head
.word_forward:
    mov rcx, -1
    mov r8, [r8]  ; start looking. 
    cmp r8, 0
    je .invalid
    mov r10, r8
    add r10, 8
.word_loop:
    inc rcx
    cmp byte[r10 + rcx], 0
    je .word_eval
    mov bpl, [r9 + rcx]
    sub bpl, [r10 + rcx]
    jz .word_loop
    jmp .word_forward
.word_eval:
    ; eval word.
    jmp [r10 + rcx + 2]
.invalid:
    sys_print [codes + codes_invalid_txt_idx], codes_invalid_txt_len
    jmp .end
.num_parse:
    ;  number.
    sys_parse_int r9
.num_eval:
    push rax
.end:
    jmp next

impl_read_word:
    sys_print [codes + codes_arrow_sign_idx], codes_arrow_sign_len
.read:
    sys_read_stdin input_buf, 0x20
    cmp rax, 1
    jle .read
    jmp next

impl_init:
    ; save %rsp;
    mov o_rsp, rsp
    mov tstack, tstack_start
    mov rstack, rstack_start  ; stack holding old outer pc.
    mov pc, repl_stub
    jmp next

impl_ret:
    mov pc, [rstack]
    add rstack, 8
    jmp next

impl_plus:
    mov r8, rsp
    add r8, 8
    cmp o_rsp, r8
    jl .end
    pop rax
    add rax, [rsp]
    mov [rsp], rax
.end:
    jmp next

impl_sub:
    mov r8, rsp
    add r8, 8
    cmp o_rsp, r8
    jl .end
    pop rax
    sub rax, [rsp]
    mov [rsp], rax
.end:
    jmp next

impl_mul:
    pop rax
    imul qword[rsp]
    mov [rsp], rax
    jmp next

impl_div:
    xor rdx, rdx
    pop rax
    idiv qword[rsp]
    mov [rsp], rax
    jmp next

impl_dup:
    push qword[rsp]
    jmp next

impl_print_top_stack:
    mov rax, [rsp]
    test eax, 1 << 15
    je .init
    not rax
    inc rax
    push rax
    sys_print [codes + codes_negative_sign_idx], 1  ; %rax will be modified.
    pop rax
.init:
    mov rcx, 10
    xor r10, r10
.loop:    
    xor rdx, rdx
    div rcx
    dec tstack
    add rdx, ascii_digits_offset
    mov r9, rdx
    mov [tstack], r9b
    inc r10
    cmp eax, 0
    jne .loop
.print:
    sys_print [tstack], r10
    sys_print [codes + codes_wrap_ctl_idx], codes_wrap_ctl_len
    mov tstack, tstack_start
    jmp next

impl_exit:
    sys_exit

; inner interpreter.
next:
    mov w, pc
    add pc, 8
    mov w, [w]  ; indirect-threaded: xt_ -> impl_.
    jmp [w]

_start:
    push 0
    jmp impl_init
    