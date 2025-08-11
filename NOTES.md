# jamesukiyo's learning notes for fasm and nasm

## General

### Registers and memory addressing

x86-64 provides 16 general purpose registers. The main ones are:
- `rax` (accumulator):  return values, syscall numbers
- `rbx`, `rcx`, `rdx`:  general computation, temporary storage
- `rsi`, `rdi`:         source and destination for ops and args
- `rsp`:                stack pointer
- `rbp`:                base pointer for stack frames
- `r8` to `r15`:        ?additional registers

Registers can be accessed in different sizes such as:
- `rax`:  u64 - 64-bit
- `eax`:  u32 - 32-bit
- `ax`:   u16 - 16-bit
- `al`:    u8 -  8-bit

When writing to a smaller register, like `EAX` for example, the upper 32-bits 
of the full register are zeroed out.

Memory addressing supports several modes:
```asm
; instruction               ; Rust comparison
mov rax, [rbx]              ; *ptr (like unsafe { *ptr })
mov rax, [rbx + 8]          ; *(ptr.add(1)) for 8 byte values
mov rax, [rbx + rcx*4]      ; slice[index] for 4 byte values
mov rax, [rbx + rcx*8 + 16] ; more complex pointer arithmetic
```

### Instructions

Moving data is the core operation. The `mov` instruction **copies** data between
locations.
```asm
mov rax, rbx                ; copy rbx to rax like `let rax = rbx`
mov rax, 42                 ; load immediate value like `let rax = 42u64`
mov rax, [rbx]              ; dereference pointer like `unsafe { *ptr }`
mov [rax], rbx              ; store through pointer like `unsafe { *ptr = val }`
```

Arithmetic operators work directly on data but do not do overflow checking.
```asm
add rax, rbx            ; rax += rbx like `rax.wrapping_add(rbx)`
sub rax, 10             ; rax -= 10
inc rax                 ; rax += 1
dec rbx                 ; rbx -= 1
```

Control flow relies on explicit comparisons and conditional jumps instead of
if expressions which return values or similar.
```asm
cmp rax, rbx            ; compare rax with rbx
je equal_label          ; jump if equal `==`
jg greater_label        ; jump if greater `>`
jmp always_label        ; unconditional jump like `loop { break }`
```

Function calls use `call` and `ret`. The first six integer arguments are passed
into registers `rdi`, `rsi`, `rdx`, `rcx`, `r8` and `r9`. This isn't type
checked.

### System calls

Syscalls are a way to call operating system functions. The number is passed in
`rax` and determines the syscall to make. Some examples:
```asm
mov rax, 0                      ; sys_read
mov rax, 1                      ; sys_write
mov rax, 60                     ; sys_exit
```

### File descriptors

File descriptors are used to determine which file to read from or write to. The
number is passed in `rdi`. Some examples:
```asm
mov rdi, 0                      ; stdin
mov rdi, 1                      ; stdout
mov rdi, 2                      ; stderr
```

### rsi and rdx

`rsi` and `rdx` are used to pass arguments to syscalls. Some examples:
```asm
mov rax, 1                      ; sys_write
mov rdi, 1                      ; stdout

mov rsi, msg                    ; `message` will be passed to sys_write
                                ; `msg` must be an address
mov rdx, msg_len                ; `msg_len` will be passed to sys_write
                                ; `msg_len` states the number of bytes
syscall                         ; call sys_write
                                ; `message` will be written to stdout
```

## FASM-specific

FASM's `format` directive determines output type.
```asm
format ELF64 executable 3   ; Linux x86-64 executable
format PE64 console         ; Windows 64-bit console app
format ELF64                ; Object file for linking
```

FASM's `segment` directive organises memory. Static data goes in `writeable`
segments and code goes in `executable` segments.
```asm
segment readable executable ; code section
segment readable writeable  ; like `static mut`
segment readable            ; like `static`
```

Data definition creates static data like `static` in Rust but uses explicit size
control.
```asm
my_byte     db 42               ; like `static MY_BYTE: u8 = 42;`
my_word     db 1234             ; like `static MY_WORD: u16 = 1234;`
my_dword    db 0x12345678       ; like `static MY_DWORD: u32 = 0x12345678;`
my_qword    db 0x12345678abcdef ; like `static MY_QWORD: u64 = 0x12345678abcdef;`
my_string   db "Hello", 0       ; like `static MY_STRING: &[u8] = b"Hello\0";`
string_len = $ - my_string      ; compile-time length calculation
```

FASM has a macro system which can generate macros similar to `macro_rules!`.
```asm
macro syscall_write fd, buffer, count {
    mov rax, 1                              ; sys_write
    mov rdi, fd
    mov rsi, buffer
    mov rdx, count
    syscall
}
; usage: syscall_write 1, message, message_len
```

Anonymous labels provide local scope similar to block expressions in Rust:
```asm
@@:                         ; anonymous label start
    inc rax                 ; increment `rax`
    cmp rax, 10             ; compare `rax` and 10
    jl  @b                  ; jump backward like `continue` in a loop
    je  @f                  ; jump forward like `break` in a loop
@@:                         ; anonymous label end
```

## NASM-specific

...

## Disorganised notes

Registers r12-15 are not affected by syscalls. I still don't understand why
and how the other registers are. A good example can be seen in
[./nasm/loop.asm](./nasm/loop.asm) and [./fasm/loop.asm](./fasm/loop.asm). Notes
are included at the bottom. After testing earlier, I found that rcx was getting
clobbered by the syscall but after switching to r12 the loop worked fine. I did
actually try r8 and that worked too but if what I've read is correct, r8 can
potentially be clobbered by the syscall whereas r12 can not. Additionally, you
can avoid clobbering by using `push` and `pop` to save and restore registers as
seen in [./nasm/word_count.asm](./nasm/word_count.asm).

The `movzx` instruction safely loads smaller values into larger registers by
zero-padding the remaining bits. For example, `movzx rax, byte [num1]` loads
only 1 byte from memory and zeros out the upper 56 bits of rax, whereas `mov
rax, [num1]` would try to load 8 bytes and grab garbage from adjacent memory.
This should prevent memory corruption when working with single-byte variables. 
A good example is in [./nasm/calculator.asm] where `mov` was reading random data
alongside my actual numbers so I switch to `movzx`. Idk yet if this is 100%
correct but from what I know so far it's good.

In NASM, data in the `section .bss` section does not take up space in the 
executable file unline the `section .data` section which stores static data. 
In FASM, unitialised data can be stored in the `segment readable writeable` 
segment and I believe this works in the same way as the `.bss` section in NASM,
meaning it doesn't take up space in the executable file. `section .bss` in NASM
appears to be the same as `segment readable` in FASM and stores static data.

