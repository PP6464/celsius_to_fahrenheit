%define STDIN 0
%define SYS_READ 0
%define NEWLINE 10

section .bss
    temp: resb 1

section .text

; Flush excess input
flush_stdin:
    ; Read a character
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rdx, 1
    lea rsi, [temp]
    syscall

    ; Check for EOF
    cmp rax, 0
    je .done

    ; Check if newline is encountered
    cmp byte [temp], NEWLINE
    jne flush_stdin
    je .done

    .done:
        ret


global read_from_stdin

; Read specified bytes of user input
; rdi: number of bytes to read
; rsi: pointer to buffer
; return: The result will be stored in the specified buffer, and number of bytes read will be stored in rax
read_from_stdin:
    ; Set up 24 byte stack frame
    ; [rbp - 8]: quadword copy of the original rdi
    ; [rbp - 16]: quadword copy of the number of bytes read
    push rbp  ; rbp is 8 bytes long (a quadword)
    mov rbp, rsp
    sub rsp, 24

    ; Put rdi onto the stack
    mov qword [rbp - 8], rdi

    ; Read the input
    mov rax, SYS_READ
    mov rdi, STDIN
    ; Remember rsi already points to the buffer
    mov rdx, qword [rbp - 8]  ; mov the length parameter into rdx
    syscall

    ; Push rax (bytes read) to the stack
    mov qword [rbp - 16], rax

    ; Flush stdin if required
    cmp rax, rdx
    jl .skip_flush
    cmp byte [rsi + rdx - 1], NEWLINE
    je .skip_flush
    call flush_stdin

    .skip_flush:

    ; Collapse the stack and return
    mov rax, qword [rbp - 16]  ; Restore rax so it has the number of bytes read
    mov rsp, rbp
    pop rbp
    ret