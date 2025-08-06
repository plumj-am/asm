format ELF64 executable 3	; Linux x86-64 output
entry start			; specify entry point

segment readable executable	; code section where all executable code lives
start:
	; CODE HERE

	; exit cleanly with sys_exit
	mov rax, 60		; system call number for exit
	mov rdi, 0		; exit status 0
	syscall			; never returns

segment readable writeable	; static data section

; STATIC DATA HERE

; example
message	db "Hello world!", 10, 0
message_len = $ - message	; `$` gives the current address
