; calculator: pick an operation and perform it on 2 single-digit numbers.
;
; Assembler: FASM
; Author: James Plummer <jamesp2001@live.co.uk>
; Source: https://github.com/jamesukiyo/asm/blob/master/fasm/calculator.asm
; Last modified: 2025-08-11
; License: MIT

format ELF64 executable 3       ; Linux x86-64 output
entry start                     ; specify entry point

segment readable writeable
choice rb 1                     ; user selected math op
num1 rb 1                       ; first input
num2 rb 1                       ; second input
result rb 2                     ; final result stored here

segment readable executable

start:
    ; write prompt
    mov rax, 1                  ; sys_write (1)
    mov rdi, 1                  ; stdout file desc (1)
    mov rsi, choice_msg         ; addr of choice prompt
    mov rdx, choice_msg_len     ; len of choice prompt
    syscall

    ; read choice input
    mov rax, 0                  ; sys_read (0)
    mov rdi, 0                  ; stdin file desc (0)
    mov rsi, choice             ; addr of choice
    mov rdx, 2                  ; 2 bytes for entered char + newline
    syscall

    ; write prompt for input 1
    mov rax, 1                  ; sys_write (1)
    mov rdi, 1                  ; stdout file desc (1)
    mov rsi, num1_input_msg     ; addr of choice prompt
    mov rdx, num1_input_msg_len ; len of choice prompt
    syscall

    ; read choice for input 1
    mov rax, 0                  ; sys_read (0)
    mov rdi, 0                  ; stdin file desc (0)
    mov rsi, num1               ; addr of choice
    mov rdx, 2                  ; 2 bytes for entered char + newline
    syscall

    ; write prompt for input 2
    mov rax, 1                  ; sys_write (1)
    mov rdi, 1                  ; stdout file desc (1)
    mov rsi, num2_input_msg     ; addr of second input msg
    mov rdx, num2_input_msg_len ; len of second input msg
    syscall

    ; read choice for input 2
    mov rax, 0                  ; sys_read (0)
    mov rdi, 0                  ; stdin file desc (0)
    mov rsi, num2               ; addr of choice
    mov rdx, 2                  ; 2 bytes for entered char + newline
    syscall

    ; convert ascii inputs to numbers
    sub byte [num1], 48
    sub byte [num2], 48

    ; conditional jumps
    cmp byte [choice], "a"      ; choice "a" jumps to `addition` label
    je addition
    cmp byte [choice], "s"      ; choice "s" jumps to `subtraction` label
    je subtraction
    cmp byte [choice], "d"      ; choice "d" jumps to `division` label
    je division
    cmp byte [choice], "m"      ; choice "m" jumps to `multiplication` label
    je multiplication
    ; NOTE: this is actually way too late in exec, need to find a better way
    ; I was hoping to make it an early return of sorts lol
    ; default case jumps to exit to handle invalid input
    jmp exit

addition:
    movzx rax, byte [num1]      ; load first number as byte* (check eof notes)
    movzx rbx, byte [num2]      ; load second number as byte
    add rax, rbx                ; add and result in rax
    
    ; convert result to two digits
    mov rbx, 10                 ; divisor to separate the digits
    mov rdx, 0                  ; clear rdx for division
    div rbx                     ; rax = "tens" digit, rdx = "ones" digit
    
    ; convert both digits to ascii
    add rax, 48                 ; "tens" digit to ascii
    add rdx, 48                 ; "ones" digit to ascii
    
    ; store in result buffer
    mov [result], al            ; first byte = "tens" digit
    mov [result+1], dl          ; second byte = "ones" digit
    jmp finish

subtraction:
    movzx rax, byte [num1]      ; load first number as byte
    movzx rbx, byte [num2]      ; load second number as byte
    sub rax, rbx                ; subtract and result in rax
    
    ; convert result to two digits
    mov rbx, 10                 ; divisor to separate the digits
    mov rdx, 0                  ; clear rdx for division
    div rbx                     ; rax = "tens" digit, rdx = "ones" digit
    
    ; convert both digits to ascii
    add rax, 48                 ; "tens" digit to ascii
    add rdx, 48                 ; "ones" digit to ascii
    
    ; store in result buffer
    mov [result], al            ; first byte = "tens" digit
    mov [result+1], dl          ; second byte = "ones" digit
    jmp finish

division:
    movzx rax, byte [num1]      ; load first number as byte
    mov rdx, 0                  ; clear rdx for division
    movzx rbx, byte [num2]      ; load second number as byte
    div rbx                     ; divide rax by rbx
    
    ; convert result to two digits
    mov rbx, 10                 ; divisor for to separate the digits
    mov rdx, 0                  ; clear rdx for division
    div rbx                     ; rax = "tens" digit, rdx = "ones" digit
    
    ; convert both digits to ascii
    add rax, 48                 ; "tens" digit to ascii
    add rdx, 48                 ; "ones" digit to ascii
    
    ; store in result buffer
    mov [result], al            ; first byte = "tens" digit
    mov [result+1], dl          ; second byte = "ones" digit
    jmp finish

multiplication:
    movzx rax, byte [num1]      ; load first number as byte
    movzx rbx, byte [num2]      ; load second number as byte  
    mul rbx                     ; multiply: result in rax
    
    ; convert result to two digits
    mov rbx, 10                 ; divisor
    mov rdx, 0                  ; clear rdx for division
    div rbx                     ; rax = "tens" digit, rdx = "ones" digit
    
    ; convert both digits to ascii
    add rax, 48                 ; "tens" digit to ascii
    add rdx, 48                 ; "ones" digit to ascii
    
    ; store in result buffer
    mov [result], al            ; first byte = "tens" digit
    mov [result+1], dl          ; second byte = "ones" digit
    
    jmp finish

finish:
    ; write output prompt
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout file desc
    mov rsi, result_output      ; addr of output prompt
    mov rdx, result_output_len  ; len of output prompt
    syscall

    ; write output data
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout file desc
    mov rsi, result             ; addr of output data
    mov rdx, 2                  ; output 2 bytes for multi-digit results
    syscall

exit:
    mov rax, 60                 ; syscall exit #
    mov rdi, 0                  ; status 0
    syscall                     ; end

segment readable
choice_msg db "Pick an op to perform (a)dd, (s)ubtract, (d)ivide, (m)ultiply: "
choice_msg_len = $ - choice_msg
num1_input_msg db "Enter a 1 digit signed integer: "
num1_input_msg_len = $ - num1_input_msg
num2_input_msg db "Enter another 1 digit signed integer: "
num2_input_msg_len = $ - num2_input_msg
result_output db "Result: "
result_output_len = $ - result_output

; * The `movzx` instruction safely loads smaller values into larger registers by
; zero-padding the remaining bits. For example, `movzx rax, byte [num1]` loads
; only 1 byte from memory and zeros out the upper 56 bits of rax, whereas `mov
; rax, [num1]` would try to load 8 bytes and grab garbage from adjacent memory.
; This should prevent memory corruption when working with single-byte variables.

; improvements that can be made:
; - handle negative numbers
; - handle div by 0
; - better div for float results
; - create shared function? for conversions
