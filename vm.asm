%include 'syscall.inc'

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

global _start
section .text

main_stub:
    dq xt_dup
    dq xt_plus
    dq xt_dbl
    dq xt_print_top_stack
    dq xt_exit
  
; dictionary (words);
nw_init:
    dq 0
    db 'init', 0
    db 0
xt_init:
    dq impl_init

nw_docol:
    dq nw_init
    db 'docol', 0
    db 0
xt_docol:
    sub rstack, 8
    mov [rstack], pc
    add w, 8
    mov pc, w
    jmp next

; return;
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

; duplicate;
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

; double;
nw_dbl:
    dq nw_dbl
    db 'dbl', 0
    db 0
xt_dbl:
    dq xt_docol
    dq xt_dup
    dq xt_plus
    dq xt_ret

_nw_head:
    dq nw_exit

; implementations;
impl_init:
    mov rstack, rstack_start  ; stack holding old outer pc;
    mov pc, main_stub
    jmp next

impl_ret:
    mov pc, [rstack]
    add rstack, 8
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
    sys_print [codes + r10], 1

impl_exit:
    sys_exit

; inner interpreter;
next:
    mov w, pc
    add pc, 8
    mov w, [w]  ; indirect-threaded: xt_ -> impl_;
    jmp [w]

_start:
    push 2
    jmp impl_init
    