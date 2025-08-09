; <NAME>: <DESC>.
;
; Assembler: NASM
; Author: James Plummer <jamesp2001@live.co.uk>
; Source: https://github.com/jamesukiyo/asm/blob/master/nasm/<NAME>.asm
; Last modified: YYYY-MM-DD
; License: MIT

section .text                     ; section for code
global _start                     ; make _start visible to the linker

_start:
    ; CODE HERE

    ; exit cleanly with sys_exit
    mov rax, 60                 ; system call number for exit
    mov rdi, 0                  ; exit status 0
    syscall                     ; never returns 

section .data                   ; static data section

; DATA HERE

; example
msg db "Hello world!", 10, 0    ; static message
msg_len equ $ - msg             ; message length computed at compile time      
; equ is `=`                    ; `$` gives the current address
