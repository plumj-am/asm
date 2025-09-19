; Name: cat
; Description: Output the contents of a file to stdout.
; Assembler: NASM
; Usage: `cat <FILE>`
; Examples:
; `cat ./nasm/hello_world`
; `cat README.md`

; This program is basically just `./word_count.asm` but simpler so it was
; quite easy to create from that as a template. Instead of processing chunks of
; data, I could just print immediately.

;================================
; UNINITIALISED DATA
;================================
section .bss
chunks resb 4096                ; chunks of input file
filename resb 256               ; user input filename buffer

;================================
; START
;================================
section .text
global _start

_start:
    ; stack layout when program starts for my reference:
    ; [rsp]     = argc (num of args)
    ; [rsp+8]   = argv[0] (program name)
    ; [rsp+16]  = argv[1] (first arg = filename)
    ; [rsp+24]  = argv[2] (second argument, not used but for reference)

    mov rax, [rsp]              ; get argc
    cmp rax, 2                  ; needs 2 args (program name and filename)
    jl usage_error              ; jump to usage_error if < 2 args

    mov rsi, [rsp+16]           ; get argv[1] ptr
    mov rdi, filename           ; get destination buffer ptr
    call copy_string            ; copy argv[1] to filename buffer

    jmp read_file               ; start reading the file

;================================
; FILE READING
;================================
read_file:
    ; open file
    mov rax, 2                  ; sys_open (2)
    mov rdi, filename           ; filename to open
    mov rsi, 0                  ; O_RDONLY flag
    mov rdx, 0                  ; 0 for readonly, no permissions needed
    syscall
    cmp rax, 0                  ; check if read failed
    jl file_error               ; jump to file_error if rax < 0 (error)
    mov r12, rax                ; store file descriptor in r12

    jmp read_loop               ; jump to start reading file chunks
read_loop:
    ; read chunk
    mov rax, 0                  ; sys_read
    mov rdi, r12                ; file descriptor
    mov rsi, chunks             ; buffer to read to
    mov rdx, 4096               ; bytes to read = buffer size 4KB
    syscall

    cmp rax, 0                  ; check bytes read
    jle close_file              ; jump to close_file if <=0 (done/error)

    mov rdx, rax                ; bytes to write = bytes to read
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, chunks             ; same chunk
    syscall

    jmp read_loop               ; continue reading

close_file:
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; file descriptor from r12
    syscall
    mov rdi, 0                  ; exit code 0
    call exit

;================================
; STRING COPYING
;================================
copy_string:
    ; rsi = source ptr (argv[1]), rdi = destination ptr (filename buffer)
copy_loop:
    movzx rax, byte [rsi]       ; get byte
    mov [rdi], al               ; store lowest byte of rax
    cmp al, 0                   ; null check
    je copy_done                ; jump to done if null
    inc rsi                     ; increment rsi
    inc rdi                     ; increment rdi
    jmp copy_loop               ; continue loop
copy_done:
    ret                         ; exit copy function

;================================
; ERROR HANDLERS
;================================
usage_error:
    ; write error message
    mov rax, 1                  ; sys_write
    mov rdi, 2                  ; stderr
    mov rsi, usage_err          ; addr of error message
    mov rdx, usage_err_len      ; len of error message
    syscall
    mov rdi, 1                  ; exit code 1
    call exit

file_error:
    ; write error message
    mov rax, 1                  ; sys_write
    mov rdi, 2                  ; stderr
    mov rsi, file_err           ; addr of error message
    mov rdx, file_err_len       ; len of error message
    syscall
    mov rdi, 1                  ; exit code 1
    call exit

;================================
; CLEAN EXIT
;================================
exit:
    ; rdi = exit code
    mov rax, 60
    syscall

;================================
; STATIC DATA
;================================
section .data
; ERRORS
usage_err db "Usage: cat <FILE>"
usage_err_len equ $ - usage_err
file_err db "An error occurred while reading the file. Please try again."
file_err_len equ $ - file_err
