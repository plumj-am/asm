; hello_world: print "Hello world!" to stdout.
;
; Assembler: NASM
; Author: James Plummer <jamesp2001@live.co.uk>
; Source: https://github.com/jamesukiyo/asm/blob/master/nasm/hello_world.asm
; Last modified: 2025-08-09
; License: MIT

section .text                   ; section for code
global _start                   ; specify entry point

_start:

    ; write "Hello world!" to stdout using sys_write
    ; like `std::io::stdout().write_all(b"Hello world!!\n").unwrap()` I think?

    mov rax, 1                  ; system call number for write
    mov rdi, 1                  ; file description 1 = stdout
    mov rsi, msg                ; buffer address
    mov rdx, msg_len            ; buffer length
    syscall                     ; invoke system call

    ; exit cleanly with sys_exit
    ; like `std::process::exit(0)`

    mov rax, 60                 ; system call number for exit
    mov rdi, 0                  ; exit status 0
    syscall                     ; never returns like `-> !`

section .data                   ; static data section

msg db "Hello world!", 10, 0    ; `static MESSAGE: &[u8] = b"Hello world!\n\0;`
msg_len equ $ - msg             ; `MESSAGE.len()` computed at compile time      
                                ; `$` gives the current address
