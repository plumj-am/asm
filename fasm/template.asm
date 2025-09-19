; Name: <NAME>
; Description: <DESCRIPTION>.
; Assembler: FASM
; Usage: `<NAME> ...`
; Examples:
; `<NAME> ...`

format ELF64 executable 3       ; Linux x86-64 output
entry start                     ; specify entry point

segment readable executable     ; code section where all executable code lives

start:
    ; CODE HERE

    ; exit cleanly
    mov rax, 60                 ; system call number for exit
    mov rdi, 0                  ; exit status 0
    syscall                     ; never returns

segment readable writeable      ; static data section

; DATA HERE

; example
msg db "Hello world!", 10, 0    ; static message
msg_len = $ - msg               ; message length computed at compile time
                                ; `$` gives the current address
