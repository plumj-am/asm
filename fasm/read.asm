; read: read an input from stdin and echo it back via stdout.
;
; Assembler: FASM
; Author: James Plummer <jamesp2001@live.co.uk>
; Source: https://github.com/jamesukiyo/asm/blob/master/fasm/read.asm
; Last modified: 2025-08-10
; License: MIT

format ELF64 executable 3
entry start 

segment readable writable
in_data db 5                    ; "data" alone is a reserved keyword in fasm

segment readable executable

start:
    ; write prompt
    mov rax, 1                  ; sys_write (1)
    mov rdi, 1                  ; stdout file desc (1)
    mov rsi, input              ; addr of input prompt
    mov rdx, input_len          ; len of input prompt
    syscall

    ; read input
    mov rax, 0                  ; sys_read (0)
    mov rdi, 0                  ; stdin file desc (0)
    mov rsi, in_data            ; addr of data
    mov rdx, 5                  ; 5 bytes - 1 for each char
    syscall
    
    ; write output prompt
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout file desc
    mov rsi, output             ; addr of output prompt
    mov rdx, output_len         ; len of output prompt
    syscall

    ; write output data
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout file desc
    mov rsi, in_data            ; addr of output data
    mov rdx, 5                  ; 5 bytes
    syscall

    ; exit
    mov rax, 60                 ; syscall exit #
    mov rdi, 0                  ; exit status 0
    syscall                     ; end


segment readable
input db "Enter 1-5 characters or numbers: "
input_len = $ - input
output db "You entered: "
output_len = $ - output
