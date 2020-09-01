%include 'syscall.inc'

; macros;
%define rstack r13
%define pc r15
%define w r14

section .data
codes:
    db '0123456789ABCDEF'  ; char symbols;

section .bss
resb 1024  ; high addr;
rstack_start:
input_buf: resb 1024

global _start
section .text

main_stub:
    dq xt_read_word
    dq xt_eval_word
    dq xt_exit

repl_stub:
    dq xt_read_word
    dq xt_eval_word
    ; dq xt_repl_reset
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
    dq nw_exit
    db 'dbl', 0
    db 0
xt_dbl:
    dq xt_docol
    dq xt_dup
    dq xt_plus
    dq xt_ret

; read_word;
nw_read_word:
    dq nw_dbl
    db 'read_word', 0
    db 0
xt_read_word:
    dq impl_read_word

; eval_word;
nw_eval_word:
    dq nw_read_word
    db 'eval_word', 0
    db 0
xt_eval_word:
    dq impl_eval_word
    
_nw_head:
    dq nw_eval_word

; implementations;
impl_eval_word:
    mov r8, _nw_head
.forward:
    mov r9, -1
    mov r8, [r8]  ; start looking;
    cmp r8, 0
    je .end
    mov r10, r8
    add r10, 8
.loop:
    inc r9
    cmp byte[r10 + r9], 0
    je .eval
    mov bpl, [input_buf + r9]
    sub bpl, [r10 + r9]
    jz .loop
    jmp .forward
.eval:
    ; eval;
    jmp [r10 + r9 + 2]
.end:
    jmp next

impl_read_word:
.read:
    sys_read_stdin input_buf, 32
    cmp rax, 1
    jle .read
    jmp next

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
    