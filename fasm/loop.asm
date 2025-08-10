; loop: print from 1 to 9 with a loop to stdout, each separated by a newline.
;
; Assembler: FASM
; Author: James Plummer <jamesp2001@live.co.uk>
; Source: https://github.com/jamesukiyo/asm/blob/master/fasm/loop.asm
; Last modified: 2025-08-10
; License: MIT

format ELF64 executable 3
entry start

start:
    mov r12, 1                  ; init counter*
loopy:                          ; "loop" alone is a reserved keyword in fasm
    mov rbx, r12                ; copy counter digit to rbx
    add rbx, 48                 ; add 48 - converts to ascii
    mov [buf], bl               ; store digit at buf[0]
    mov byte [buf+1], 10        ; add newline character (10) at buf[1]
    mov rsi, buf                ; msg to write (buf addr)
    mov rdx, 2                  ; msg length (2 bytes)
    mov rax, 1                  ; syscall write #
    mov rdi, 1                  ; stdout file descriptor #
    syscall                     ; call kernel for write
    inc r12                     ; r12++
    cmp r12, 10                 ; r12 < 10 ?
    jl loopy                    ; jump to loop start or fall through

    mov rax, 60                 ; syscall exit #
    mov rdi, 0                  ; status 0
    syscall                     ; end

segment readable writeable
buf db 0, 0                     ; 2 byte buffer for char + \n

; * I used register r12 because r12-15 are untouched by syscalls. I don't fully
; understand why and how yet but using rcx failed because the write to stdout
; syscall clobbered the rcx register and caused the loop to exit at 1.
