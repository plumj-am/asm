; head: output the contents of a file down to a specified line to stdout.
;
; usage: `head <FILE> <LINE>`
; examples: 
; `head ./nasm/hello_world 50`
; `head README.md 24`
;
; Assembler: NASM
; Author: James Plummer <jamesp2001@live.co.uk>
; Source: https://github.com/jamesukiyo/asm/blob/master/nasm/head.asm
; Last modified: 2025-08-12
; License: MIT

; Very similar implementation to `cat` and `word_count` so a lot of the logic
; has been copied. The difference is that here we take a second argument and use 
; it to determine at what line we should stop reading the file. Also need to
; handle partial chunks since the final newline which indicates the end of the
; users requested line count can be in the middle of a chunk.

;================================
; UNINITIALISED DATA
;================================
section .bss
chunks resb 4096                ; chunks of input file
filename resb 256               ; user input filename buffer
line_count resq 1               ; track line count, qword so 8 bytes
max_lines resq 1                ; arg 2 number of lines, qword so 8 bytes

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
    cmp rax, 3                  ; needs 3 args (prog name, filename, line)
    jl usage_error              ; jump to usage_error if < 3 args

    mov rsi, [rsp+16]           ; get argv[1] ptr
    mov rdi, filename           ; get destination buffer ptr
    call copy_string            ; copy argv[1] to filename buffer

    mov rsi, [rsp+24]           ; get argv[2] ptr
    call convert_number         ; convert ascii input to number
    mov [max_lines], rax        ; convert_number returns number in rax

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

    ; process chunks
    mov rcx, rax                ; bytes read count
    mov rsi, chunks             ; buffer start
    call process_chunk          ; process the current chunk
    
    jmp read_loop               ; continue reading

close_file:
    mov rax, 3                  ; sys_close
    mov rdi, r12                ; file descriptor from r12
    syscall
    mov rdi, 0                  ; exit code 0
    call exit

;================================
; LINE COUNTING LOGIC
;================================
process_chunk:
    ; rcx = bytes to process, rsi = buffer start
    mov r13, rsi                ; save original buffer start
    mov r14, rcx                ; save original byte count

process_char:
   cmp rcx, 0                   ; check if done 
   je write_full_chunk          ; write entire chunk if processed all

   movzx rax, byte [rsi]        ; get current char

   ; check for newline
   cmp al, 10                   ; 10=newline
   jne next_char                ; skip if not newline

   ; found newline
   inc qword [line_count]       ; line count += 1
   mov rax, [line_count]        ; get current count
   cmp rax, [max_lines]         ; reached limit?
   jge write_partial_chunk      ; write up to this point and stop

next_char:
    inc rsi                     ; next char
    dec rcx                     ; decrement remaining char count
    jmp process_char            ; continue loop

write_partial_chunk:
    ; write only up to curr position (with newline via inc)
    inc rsi                     ; extend byte range to include the newline
    sub rsi, r13                ; bytes to write = curr pos - start
    mov rdx, rsi                ; bytes to write
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, r13                ; original buffer start
    syscall
    jmp close_file

write_full_chunk:
    ; write entire chunk normally
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, r13                ; original buffer start
    mov rdx, r14                ; original byte count
    syscall
    ret

process_done:
    ret

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
; ASCII TO NUMBER CONVERSION
;================================

convert_number:
    ; rsi = ptr to string (e.g. "25")
    mov rax, 0                  ; result accumulator
    mov rbx, 10                 ; multiplier
convert_loop:
    movzx rcx, byte [rsi]       ; get curr digit char
    cmp rcx, 0                  ; check for null terminator
    je convert_done             ; jump to convert_done if finished

    sub rcx, 48                 ; convert ascii to number

    mul rbx                     ; rax = rax * rbx (10 in rbx)
    add rax, rcx                ; rax += digit

    inc rsi                     ; next char
    jmp convert_loop            ; continue converting
    
convert_done:
    ret                         ; rax now contains the number

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
usage_err db "Incorrect or broken args provided. Please provide 2 args that are\
 the full name of the file to preview and the number of lines to display."
usage_err_len equ $ - usage_err
file_err db "An error occurred while reading the file. Please try again."
file_err_len equ $ - file_err
