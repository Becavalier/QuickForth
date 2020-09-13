%include 'sys_call.inc'
%include 'sys_transform.inc'

; macros (%rcx and %r11 could be modified by syscall).
%define rstack r13
%define astack rbx
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

%macro GUARD_STACK_LEN 1
    mov r8, rsp
    add r8, 4 * %1
    cmp o_rsp, r8
    jl .end
%endmacro

section .data
codes:
    db `0123456789ABCDEF> \n\r(invalid)\n\r-`  ; char symbols.

section .bss
; stacks.
resb 1024
attach_stack_start:
resb 1024  ; high addr.
return_stack_start:
; static memory.
input_buf: resb 1024
program_stub: resb 16

global _start
section .text

compilation_stub:
    ; ready to go.
    dq xt_exit

repl_stub:
    dq xt_read_word
    dq xt_eval_word
    dq xt_repl_reset

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
nw_colon:
    dq nw_docol
    db ':', 0
    db 0
xt_colon:
    dq impl_colon

nw_ret:
    dq nw_colon
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

nw_mod:
    dq nw_div
    db '%', 0
    db 0
xt_mod:
    dq impl_mod

nw_dup:
    dq nw_mod
    db 'dup', 0
    db 0
xt_dup:
    dq impl_dup

nw_not:
    dq nw_dup
    db '!', 0
    db 0
xt_not:
    dq impl_not

nw_equal:
    dq nw_not
    db '=', 0
    db 0
xt_equal:
    dq impl_equal

nw_print_top_stack:
    dq nw_equal
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

nw_print_all_stack:
    dq nw_rot
    db '.S', 0
    db 0
xt_print_all_stack:
    dq impl_print_all_stack

nw_drop_print:
    dq nw_print_all_stack
    db '.', 0
    db 0
xt_drop_print:
    dq xt_docol
    dq xt_print_top_stack
    dq xt_drop
    dq xt_ret

_nw_last:
    dq nw_docol

_nw_head:
    dq nw_drop_print

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
    sub astack, 8
    mov [astack], r10
    add rsp, 8
    inc r8
    jmp .start
.last:
    pop r9
.loop:
    cmp r8, 0
    je .over
    push qword[astack]
    add astack, 8
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
    GUARD_STACK_LEN 1
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
    jne .continue
    cmp byte[r9 + rcx], `\n`
    je .word_eval
.continue:
    mov bpl, [r9 + rcx]  ; input char;
    sub bpl, [r10 + rcx]  ; comparing char;
    jz .word_loop
    jmp .word_forward
.word_eval:
    ; eval word.
    lea r8, [r10 + rcx + 2]
    mov [program_stub], r8
    mov qword[program_stub + 8], xt_repl_reset
    mov pc, program_stub  ; dynamic threading.
    jmp next
.invalid:
    sys_print [codes + codes_invalid_txt_idx], codes_invalid_txt_len
    jmp .end
.num_parse:
    ; number.
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
    xor rbp, rbp
    mov o_rsp, rsp
    mov astack, attach_stack_start
    mov rstack, return_stack_start  ; stack holding old outer pc.
    mov pc, repl_stub
    jmp next

impl_ret:
    mov pc, [rstack]
    add rstack, 8
    jmp next

impl_colon:

    jmp next

impl_plus:
    GUARD_STACK_LEN 2
    pop rax
    add rax, [rsp]
    mov [rsp], rax
.end:
    jmp next

impl_sub:
    GUARD_STACK_LEN 2
    pop rax
    sub rax, [rsp]
    mov [rsp], rax
.end:
    jmp next

impl_mul:
    GUARD_STACK_LEN 2
    pop rax
    imul qword[rsp]
    mov [rsp], rax
.end:
    jmp next

impl_div:
    GUARD_STACK_LEN 2                                                                                                                                                                           
    xor rdx, rdx
    pop rax
    idiv qword[rsp]
    mov [rsp], rax
.end:
    jmp next

impl_mod:
    GUARD_STACK_LEN 2
    xor rdx, rdx
    pop rax
    idiv qword[rsp]
    mov [rsp], rdx
.end:
    jmp next

impl_not:
    GUARD_STACK_LEN 1
    pop rax
    cmp rax, 0
    je .true
    push 0
    jmp .end
.true:
    push 1
.end:
    jmp next

impl_equal:
    GUARD_STACK_LEN 2
    pop rax
    pop r8
    cmp rax, r8
    je .equal
    push 0
    jmp .end
.equal:
    push 1
.end:
    jmp next

impl_dup:
    push qword[rsp]
    jmp next

impl_print_all_stack:
    xor rbp, rbp
.loop:
    lea r8, [rsp + 8 * rbp]
    cmp o_rsp, r8
    jle .end
    mov r10, 2 << 5
    mov qword[program_stub], .continue  ; cross the next instruction;
    jmp impl_print_top_stack
.continue:
    inc rbp
    jmp .loop
.end:
    jmp next

; %rbp - stack base;
; %r10 - redirection flag;
impl_print_top_stack:
    mov rax, [rsp + 8 * rbp]
    test eax, 1 << 15
    je .init
    not rax
    inc rax
    push rax
    sys_print [codes + codes_negative_sign_idx], 1  ; %rax will be modified.
    pop rax
.init:
    mov rcx, 10
    xor r8, r8
.loop:    
    xor rdx, rdx
    div rcx
    dec astack
    add rdx, ascii_digits_offset
    mov r9, rdx
    mov [astack], r9b
    inc r8
    cmp eax, 0
    jne .loop
.print:
    sys_print [astack], r8
    sys_print [codes + codes_wrap_ctl_idx], codes_wrap_ctl_len
    mov astack, attach_stack_start
    cmp r10, 2 << 5
    jne .end 
.jump:
    jmp [program_stub]
.end:
    jmp next

impl_exit:
    sys_exit

; inner interpreter.
next:
    mov w, [pc]  ; indirect-threaded: xt_ -> impl_.
    add pc, 8
    jmp [w]

_start:
    push 0
    jmp impl_init
    