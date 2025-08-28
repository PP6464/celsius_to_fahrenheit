%define STDOUT 1
%define STDERR 2
%define SYS_WRITE 1
%define NEWLINE 10

section .text

global length_of_string

; Gives the length of a string that is newline-terminated or zero-terminated
; Need to also check for zero-terminated strings if the input has been flushed
; rdi: pointer to the start of the string
; return: length of string (w/o newline) in rax
length_of_string:
    mov rax, 0

    .next_char:
        ; Check for newline
        cmp byte [rdi + rax], NEWLINE
        je .done
        ; Check for zero
        cmp byte [rdi + rax], 0
        je .done

        inc rax
        jmp .next_char

    .done:
        ret

global print
global println
global println_error

; Prints a string
; rdi: pointer to string
print:
    call length_of_string  ; string ptr already in rdi
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rsi, rdi
    mov rdi, STDOUT
    syscall

    ret

; Prints a string with a newline
; rdi: pointer to string
println:
    call length_of_string
    mov byte [rdi + rax], NEWLINE  ; Put a newline at the end
    inc rax  ; This includes the '\n' character at the end
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rsi, rdi
    mov rdi, STDOUT
    syscall

    ret


; Prints a string to the STDERR stream
; Normally as this would be the last message printed we would want it to print with a newline (to ensure there is no pesky % sign)
; rdi: pointer to string
println_error:
    call length_of_string
    mov byte [rdi + rax], NEWLINE
    inc rax  ; Include the newline character
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rsi, rdi
    mov rdi, STDERR
    syscall
    
    ret
