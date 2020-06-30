; macros;
%define rstack r13
%define pc r15
%define w r14

section .data
codes:
    db '0123456789ABCDEF'  ; char symbols;

section .bss
resb 1023  ; high addr;
rstack_start:
    resb 1

global _start
section .text

main_stub:
    dq xt_dup
    dq xt_plus
    dq xt_print_top_stack
    dq xt_exit
  
; dictionary;
nw_init:
    dq 0
    db 'init', 0
    db 0
xt_init:
    dq impl_init

nw_plus:
    dq nw_init
    db '+', 0
    db 0
xt_plus:
    dq impl_plus

nw_dup:
    dq nw_plus
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

_nw_head:
    dq nw_exit

; implementations;
impl_init:
    mov rstack, rstack_start
    mov pc, main_stub
    jmp next

impl_plus:
    pop rax
    add rax, [rsp]
    mov [rsp], rax
    jmp next

impl_dup:
    push qword[rsp]
    jmp next

impl_print_top_stack:
    mov r10, [rsp]
    mov rdi, 1
    mov rdx, 1
    mov rax, 1
    lea rsi, [codes + r10]
    syscall

impl_exit:
    xor rdi, rdi
    mov rax, 60
    syscall

; inner interpreter;
next:
    mov w, pc
    add pc, 8
    mov w, [w]
    jmp [w]

_start:
    push 3
    jmp impl_init