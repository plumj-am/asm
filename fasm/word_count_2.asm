; Name: word_count_2
; Description: Count the number of words in a file. This is an improved version
; of the original word_count program that will be incrementally improved as I
; learn more.
; Changes compared to the original:
; - macro for sys_write
; - ... wip
; Assembler: FASM
; Usage: `word_count_2 <FILE>`
; Examples:
; `word_count_2 ./fasm/hello_world`
; `word_count_2 README.md`

format ELF64 executable 3
entry start

;================================
; UNINITIALISED DATA
;================================
segment readable writeable
chunks rb 4096                  ; chunks of input file
filename rb 256                 ; user input filename buffer
wc rq 1                         ; track word count with qword (8 bytes)
in_word rb 1                    ; in word? flag
digit_tmp rb 1                  ; temporary storage for digits

;================================
; START
;================================
segment readable executable
start:
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
; MACROS
;================================
macro syscall_write file_descriptor, buffer, length {
    mov rax, 1                  ; sys_write
    mov rdi, file_descriptor    ; file descriptor
    mov rsi, buffer             ; buffer
    mov rdx, length             ; buffer length
    syscall
}

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
    mov rdx, 4096               ; bytes to read = buffer size
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
    jmp output_results

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
; WORD COUNTING
;================================
process_chunk:
    ; rcx = bytes to process, rsi = buffer start
process_char:
   cmp rcx, 0                   ; check if done
   je process_done              ; jump to process_done if rcx==0

   movzx rax, byte [rsi]        ; get current char

   ; check for whitespace
   cmp al, 32                   ; 32=space
   je handle_whitespace
   cmp al, 9                    ; 9=tab
   je handle_whitespace
   cmp al, 10                   ; 10=newline
   je handle_whitespace

   ; non-whitespace handling
   cmp byte [in_word], 0        ; check if in a word
   jne next_char                ; if yes don't count it again

   ; start of new word
   mov byte [in_word], 1        ; mark as in_word
   inc qword [wc]               ; word count += 1
   jmp next_char                ; continue

handle_whitespace:
    mov byte [in_word], 0       ; mark as not in_word

next_char:
    inc rsi                     ; next char
    dec rcx                     ; decrement remaining char count
    jmp process_char            ; continue loop

process_done:
    ret

;================================
; OUTPUT FINAL RESULTS
;================================
output_results:
    ; write message
    syscall_write 1, output, output_len

    mov rax, [wc]               ; get the word count value
    call print_number           ; convert to number and print it

    syscall_write 1, newline, 1

    mov rdi, 0                  ; exit code 0
    call exit

;================================
; NUMBER PRINTING
;================================
print_number:
    cmp rax, 0                  ; check for 0
    je handle_zero              ; jump to handle_zero for special case

    ; handle multi-digit nums
    mov rbx, 10                 ; divisor
    mov rcx, 0                  ; digit counter

digit_loop:
    mov rdx, 0                  ; clear rdx for division
    div rbx                     ; rax /= 10, rdx = remainder
    add rdx, 48                 ; convert remainder to ascii
    push rdx                    ; push digit to stack to save it
    inc rcx                     ; increment digit counter

    cmp rax, 0                  ; check for more digits
    jne digit_loop              ; if not zero, continue looping

print_loop:
    cmp rcx, 0                  ; check for more digits
    je print_done               ; if no more, finish printing

    pop rax                     ; get digit from stack
    mov [digit_tmp], al         ; store lowest byte (the digit)

    push rcx                    ; save digit counter to prevent syscall clobber

    syscall_write 1, digit_tmp, 1

    pop rcx                     ; restore digit counter
    dec rcx                     ; digit counter -= 1
    jmp print_loop              ; continue loop

print_done:
    ret

handle_zero:
    mov byte [digit_tmp], 48    ; move ascii "0" to temporary buffer

    syscall_write 1, digit_tmp, 1
    ret

;================================
; ERROR HANDLERS
;================================
usage_error:
    ; write error message
    syscall_write 2, usage_err, usage_err_len

    mov rdi, 1                  ; exit code 1
    call exit

file_error:
    ; write error message
    syscall_write 2, file_err, file_err_len

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
segment readable
; MISC
newline db 10
; OUTPUT
output db "The total word count of the file is: "
output_len = $ - output
; ERRORS
usage_err db "Usage: word_count <FILE>"
usage_err_len = $ - usage_err
file_err db "An error occurred while reading the file. Please try again."
file_err_len = $ - file_err
