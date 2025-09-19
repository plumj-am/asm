; Name: ascii_conversion
; Description: Convert an 8-bit number `n` to ascii and print to stdout.
; Assembler: FASM
; Usage: `ascii_conversion <NUMBER>`
; Examples:
; `ascii_conversion 8`

format ELF64 executable 3       ; Linux x86-64 output
entry start                     ; specify entry point

segment readable executable     ; code section where all executable code lives

start:

    mov rax, 1                  ; system call number for write
    mov rdi, 1                  ; file descriptor 1 (stdout)
    mov bl, n + 48              ; `n` in 8 lowest bits of rbx (bl), +48 converts to ascii
    mov [buf], bl               ; overwrite value from bl (lowest byte rbx) to buffer
    mov rsi, buf                ; message to write (address of buffer)
    mov rdx, 1                  ; message length (1 byte)
    syscall                     ; call kernel

    ; exit cleanly
    mov rax, 60                 ; system call number for exit
    mov rdi, 0                  ; exit status 0
    syscall                     ; never returns

segment readable writeable      ; data section

n = 5                           ; value to convert to ascii and print to stdout
buf db 0                        ; define byte (db) buffer with size 0
                                ; doesn't matter since it will be overwritten
                                ; size only matters if reading from it but we
                                ; immediately overwrite it
