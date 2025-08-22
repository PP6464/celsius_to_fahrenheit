%define CHR_0 48
%define CHR_9 57
%define CHR_HYPHEN 45
%define CHR_POINT 46

%define VALID 1
%define INVALID 0

%define NO_PREV_CHARS 0
%define PREV_NUM 1
%define PREV_HYPHEN 2
%define PREV_POINT 3

section .text

global validate_for_float
global validate_for_int
extern length_of_string

; Ensure the given string input is a valid float
; rdi: pointer to start of input
; return: 0 or 1 in rax (0 for invalid, 1 for valid)
validate_for_float:
    call length_of_string  ; rax now contains the length of the string

    ; If the string is empty then consider input invalid
    cmp rax, 0
    je .invalid

    ; Set up a 8-byte stack frame (ensures 16-byte alignment after pushing rbp)
    ; [rbp - 1]: byte counter for the number of characters encountered
    ; [rbp - 2]: byte counter for the number of '-' seen: should be one '-' seen and only at the start
    ; [rbp - 3]: byte counter for the number of '.' seen: only one should be seen and should be after a number
    ; [rbp - 4]: byte to store the type of the previous character as defined above (see prev char types)
    ; PS: cl will contain length of string (only 1 byte required as INPUT_BUFFER_SIZE <= 255)
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov dword [rbp - 4], 0  ; clears [rbp - 4] through to [rbp - 1]
    mov byte [rbp - 4], NO_PREV_CHARS  ; no previous chars at the start
    mov cl, al  ; save a copy of the length to cl

    .next_char:
        ; Put address of current char in rsi
        mov rax, [rbp - 1]
        lea rsi, [rax + rdi]

        .check_digit:
            cmp byte [rsi], CHR_0
            jl .check_hyphen
            cmp byte [rsi], CHR_9
            jg .check_hyphen

            ; If we reach this point then the current char is a digit so it is fine
            mov byte [rbp - 4], PREV_NUM  ; Encountered a number
            jmp .current_char_ok

        .check_hyphen:
            cmp byte [rsi], CHR_HYPHEN
            jne .check_decimal

            ; If there was already a hyphen then it must be invalid
            cmp byte [rbp - 2], 0
            jg .invalid

            ; We know [rbp - 4] == NO_PREV_CHARS means that there are no previous characters, which is just what we require
            cmp byte [rbp - 4], NO_PREV_CHARS
            jne .invalid

            ; If we reach this point then the current character is a valid hyphen
            inc byte [rbp - 2]
            mov byte [rbp - 4], PREV_HYPHEN
            jmp .current_char_ok

        .check_decimal:
            cmp byte [rsi], CHR_POINT
            jne .invalid  ; This character is neither a digit, hyphen or point so must be invalid 

            ; If there was already a point then the string is invalid
            cmp byte [rbp - 3], 0
            jg .invalid

            ; The previous character should be a digit
            cmp byte [rbp - 4], PREV_NUM
            jne .invalid

            ; The current character is a valid point
            mov byte [rbp - 4], PREV_POINT
            inc byte [rbp - 3]
            jmp .current_char_ok

        .current_char_ok:
            ; Check if this is meant to be the last character
            inc byte [rbp - 1]
            cmp byte [rbp - 1], cl
            je .check_last_char
            jmp .next_char

    .check_last_char:
        cmp byte [rbp - 4], PREV_NUM  ; The last character should be a number for the input to be valid
        jne .invalid        

    .valid:
        mov rax, 1

        ; Collapse stack
        mov rsp, rbp
        pop rbp

        ret

    .invalid:
        mov rax, 0

        ; Collapse stack
        mov rsp, rbp
        pop rbp

        ret

; Ensure the given string input is a valid int
; rdi: pointer to start of input
; return: 0 or 1 in rax (0 for invalid, 1 for valid)
validate_for_int:
    call length_of_string  ; rax now contains the length of the string

    ; If the string is empty then consider input invalid
    cmp rax, 0
    je .invalid

    ; Set up a 8-byte stack frame (ensures 16-byte alignment after pushing rbp)
    ; [rbp - 1]: byte counter for the number of characters encountered
    ; [rbp - 2]: byte counter for the number of '-' seen: should be one '-' seen and only at the start
    ; [rbp - 3]: byte to store the type of the previous character as defined above (see prev char types)
    ; PS: cl will contain length of string (only 1 byte required as INPUT_BUFFER_SIZE <= 255)
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov dword [rbp - 4], 0  ; clears [rbp - 4] through to [rbp - 1]
    mov byte [rbp - 3], NO_PREV_CHARS  ; no previous chars at the start
    mov cl, al  ; save a copy of the length to cl

    .next_char:
        ; Put address of current char in rsi
        mov rax, [rbp - 1]
        lea rsi, [rax + rdi]

        .check_digit:
            cmp byte [rsi], CHR_0
            jl .check_hyphen
            cmp byte [rsi], CHR_9
            jg .check_hyphen

            ; If we reach this point then the current char is a digit so it is fine
            mov byte [rbp - 3], PREV_NUM  ; Encountered a number
            jmp .current_char_ok

        .check_hyphen:
            cmp byte [rsi], CHR_HYPHEN
            jne .invalid

            ; If there was already a hyphen then it must be invalid
            cmp byte [rbp - 2], 0
            jg .invalid

            ; We know [rbp - 3] == NO_PREV_CHARS means that there are no previous characters, which is just what we require
            cmp byte [rbp - 3], NO_PREV_CHARS
            jne .invalid

            ; If we reach this point then the current character is a valid hyphen
            inc byte [rbp - 2]
            mov byte [rbp - 3], PREV_HYPHEN
            jmp .current_char_ok

        .current_char_ok:
            ; Check if this is meant to be the last character
            inc byte [rbp - 1]
            cmp byte [rbp - 1], cl
            je .valid
            jmp .next_char

    .valid:
        mov rax, 1

        ; Collapse stack
        mov rsp, rbp
        pop rbp

        ret

    .invalid:
        mov rax, 0

        ; Collapse stack
        mov rsp, rbp
        pop rbp

        ret
