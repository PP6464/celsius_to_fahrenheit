%define CHR_HYPHEN 45
%define CHR_0 48
%define NEWLINE 10

extern length_of_string

global celsius_to_fahrenheit
global convert_string_to_32_bit_int
global convert_32_bit_int_to_string

; Converts a string to a signed 32-bit integer
; rdi: pointer to start of string
; rsi: pointer to integer buffer (4 bytes)
; return: the integer will be stored in the specified buffer 
convert_string_to_32_bit_int:
    call length_of_string  ; string pointer already in rdi
    mov cl, al  ; store the length in cl

    ; Set up an 8-byte stack frame
    ; [rbp - 1]: Whether or not there was a hyphen (to multiply by -1 at the end)
    ; [rbp - 2]: byte counter for how many characters encountered
    ; PS: cl will contain the length of the string
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov word [rbp - 2], 0
    mov rax, 0  ; Clear rax

    .next_char:
        mov al, byte [rbp - 2]  ; rax now has the number of characters encountered
        cmp byte [rdi + rax], CHR_HYPHEN
        jne .not_hyphen
        inc byte [rbp - 1]  ; Encountered a hyphen
        inc byte [rbp - 2]
        jmp .next_char

        .not_hyphen:
            imul ebx, dword [rsi], 10  ; Multiply the current value by 10 and move it into ebx
            movzx edx, byte [rdi + rax]
            add ebx, edx
            sub ebx, CHR_0 ; Want to add the value of the digit, not the ASCII code
            mov dword [rsi], ebx  ; Store the current value back into the buffer

        ; Check if this was meant to be the last character
        inc byte [rbp - 2]
        cmp byte [rbp - 2], cl
        jl .next_char

    cmp byte [rbp - 1], 0
    je .done

    .check_for_minus:
        ; Negate the integer if it is meant to be negative
        imul ebx, dword [rsi], -1
        mov dword [rsi], ebx

    .done:
        ; Collapse the stack and return
        mov rsp, rbp
        pop rbp
        ret


; Convert celsius to fahrenheit
; rdi: pointer to celsius integer buffer (4 bytes)
; rsi: pointer to fahrenheit output integer buffer (4 bytes)
; return: fahrenheit value stored in the specified output buffer
celsius_to_fahrenheit:
    ; Notice how multiplying by 1.8 is the same as multiplying by 9 then dividing by 5
    imul eax, dword [rdi], 9
    cdq  ; Sign extend into edx:eax
    mov ecx, 5
    idiv ecx
    ; Now eax contains the output, and edx contains the remainder
    add eax, 32
    mov dword [rsi], eax  ; store the output where desired

    ret

; Converts a 32-bit integer to a string
; rdi: pointer to integer buffer (4 bytes)
; rsi: pointer to string buffer
; return: the string will be stored in the specified output buffer
convert_32_bit_int_to_string:
    ; Check whether the integer is positive or negative
    mov eax, dword [rdi]
    and eax, 1 << 31
    shr eax, 31  ; eax will now contain 0 or 1: 0 is positive, 1 is negative
    cmp eax, 0
    je .positive
    cmp eax, 1
    je .negative

    .negative:
        mov ebx, 10  ; Need the value 10 in a register
        mov eax, dword [rdi]
        ; Get the absolute value of eax in eax
        xor eax, (1 << 32) - 1
        inc eax

        mov ecx, 0  ; Use ecx to count the number of digits
        mov byte [rsi], CHR_HYPHEN  ; Negative numbers start with '-'

        ; While eax > 0 continue building the string
        .build_string_neg:
            cmp eax, 0
            je .done_neg
            cdq  ; Sign-extend eax into edx:eax
            idiv ebx  ; Divide by 10: This then automatically 'shifts' (in base 10) eax one to the right
            mov ebx, ecx  ; Temporarily save ecx

            .shift_chars_neg:
                ; Need to shift chars by a byte to make space for the next one
                cmp ecx, 0
                je .add_next_digit_neg
                
                mov r8b, byte [rsi + rcx]
                mov byte [rsi + rcx + 1], r8b
                dec ecx
                jmp .shift_chars_neg

            .add_next_digit_neg:
                mov ecx, ebx  ; Restore ecx
                mov ebx, 10  ; Restore ebx to 10
                inc ecx  ; Encountered a digit
                add dl, CHR_0
                mov byte [rsi + 1], dl ; Don't need to worry about overflow as edx is a remainder mod 10 plus CHR_0, so it's at most 57
                jmp .build_string_neg
        
        .done_neg:
            mov dl, NEWLINE
            mov byte[rsi + rcx + 1], dl
            ret

    .positive:
        mov ebx, 10  ; Need the value 10 in a register
        mov eax, dword [rdi]
        mov ecx, 0  ; Use ecx to count the number of digits

        ; While eax > 0 continue building the string
        .build_string_pos:
            cmp eax, 0
            je .done_pos
            cdq  ; Sign-extend eax into edx:eax
            idiv ebx  ; Divide by 10: This then automatically 'shifts' (in base 10) eax one to the right
            mov ebx, ecx  ; Temporarily save ecx

            .shift_chars_pos:
                ; Need to shift chars by a byte to make space for the next one
                cmp ecx, 0
                je .add_next_digit_pos
                
                mov r8b, byte [rsi + rcx - 1]
                mov byte [rsi + rcx], r8b
                dec ecx
                jmp .shift_chars_pos

            .add_next_digit_pos:
                mov ecx, ebx  ; Restore ecx
                mov ebx, 10  ; Restore ebx to 10
                inc ecx  ; Encountered a digit
                add dl, CHR_0
                mov byte [rsi], dl  ; Don't need to worry about overflow as edx is a remainder mod 10 plus CHR_0, so it's at most 57
                jmp .build_string_pos
        
        .done_pos:
            ; Put a newline after the the end of the string
            mov dl, NEWLINE
            mov byte [rsi + rcx], dl
            ret
