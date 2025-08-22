%define CHR_HYPHEN 45
%define CHR_POINT 46
%define CHR_0 48
%define CHR_9 57
%define NEWLINE 10
%define DP 2  ; Number of decimal places

extern length_of_string

global celsius_to_fahrenheit_int
global celsius_to_fahrenheit
global convert_string_to_32_bit_int
global convert_32_bit_int_to_string
global convert_string_to_float
global convert_float_to_string

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


; Convert celsius int to fahrenheit int
; rdi: pointer to celsius integer buffer (4 bytes)
; rsi: pointer to fahrenheit output integer buffer (4 bytes)
; return: fahrenheit value stored in the specified output buffer
celsius_to_fahrenheit_int:
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
; return: the string will be stored in the specified output buffer, and the length of the string will be stored in rax
convert_32_bit_int_to_string:
    ; If the input is 0, then just write 0 to the string
    cmp dword [rdi], 0
    jne .its_not_zero
    mov byte [rsi], CHR_0
    mov rax, 1
    ret

    .its_not_zero:
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
            ; Store the length in rax
            mov rax, rcx
            inc rax  ; For the hyphen
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
            ; Store the length in rax
            mov rax, rcx
            ret

; Converts a string to a 32-bit float
; Expects valid input string, please check using the validator
; rdi: pointer to start of string buffer
; rsi: pointer to float buffer (4 bytes)
; return: the float will be stored in the specified buffer
convert_string_to_float:
    call length_of_string  ; string pointer already in rdi
    fninit  ; Reset the FPU stack ignoring exceptions

    ; Set up a 40-byte stack
    ; [rbp - 4]: dword counter for the integer part
    ; [rbp - 8]: dword counter for the denominator (which will be a power of 10)
    ; [rbp - 9]: byte counter for whether or not the input is negative (0 = positive, 1 = negative)
    ; [rbp - 10]: byte counter for whether or not a decimal point has been encountered (0 = none, 1 = encountered)
    ; [rbp - 18]: qword address of next character to be parsed
    ; [rbp - 26]: qword address for end of string
    ; [rbp - 30]: dword to store -1 (if required, see check_neg label)
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Initialise stack
    mov qword [rbp - 8], 0
    mov dword [rbp - 10], 0
    mov dword [rbp - 30], -1

    ; Start off at the very first char
    mov qword [rbp - 18], rdi

    ; Calculate end of string
    mov qword [rbp - 26], rdi
    add qword [rbp - 26], rax
    dec qword [rbp - 26]

    ; Check if the input is negative (it would start with a hyphen)
    cmp byte [rdi], CHR_HYPHEN
    jne .parse_float  ; If not negative then skip the next lines

    ; Only if the input is negative
    inc byte [rbp - 9]
    inc qword [rbp - 18]

    .parse_float:
        ; Load address into rax
        mov rax, qword [rbp - 18]

        .check_point:
            ; If the current char is a point we will run this code
            cmp byte [rax], CHR_POINT
            jne .check_digit

            inc byte [rbp - 10]

            jmp .loop_check

        .check_digit:
            ; The current char is not a point or hyphen so must be a digit
            
            ; Save the current digit
            mov ebx, 0
            mov bl, byte [rax]
            sub ebx, CHR_0

            ; Add the current digit to the current integer part
            imul eax, dword [rbp - 4], 10
            add eax, ebx
            mov dword [rbp - 4], eax

            cmp byte [rbp - 10], 0
            je .loop_check

            ; If we reach this point then we are after the decimal point so need to increment the divisor's power of 10
            cmp dword [rbp - 8], 0
            jne .scale
            inc dword [rbp - 8]

            .scale:
                imul ebx, dword [rbp - 8], 10
                mov dword [rbp - 8], ebx

        .loop_check:
            ; Check if this is meant to be the last character
            mov rax, qword [rbp - 26]
            cmp qword [rbp - 18], rax
            je .construct_float
            inc qword [rbp - 18]
            jmp .parse_float

    .construct_float:
        fild dword [rbp - 4]  ; Move the integer part to ST0 (fild for integers)
        cmp dword [rbp - 8], 0
        jne .divide  ; Can divide if we are not dividing by 0
        mov dword [rbp - 8], 1  ; if [rbp - 8] == 0, then that means there is no decimal point, so just divide by 1

        .divide:
            fidiv dword [rbp - 8]  ; Divide by the corresponding power of 10 (use fidiv because [rbp - 8] is an integer)

    .check_neg:
        cmp byte [rbp - 9], 1
        jne .done
        fidiv dword [rbp - 30]

    .done:
        ; Move the output from ST0 to the buffer pointed to by rsi
        fstp dword [rsi]

        ; Collapse stack and return
        mov rsp, rbp
        pop rbp
        ret

; Calculates the Fahrenheit temperature from the Celsius temperature
; rdi: pointer to celsius temperature buffer (4 bytes)
; rsi: pointer to fahrenheit temperature buffer (4 bytes)
; return: the temperature will be stored as a 32-bit float in the specified buffer
celsius_to_fahrenheit:
    fninit  ; Reset the FPU stack ignoring exceptions

    ; load the input float to ST0
    fld dword [rdi]

    ; Set up an 8-byte stack
    ; [rbp - 2]: word to store 5
    ; [rbp - 4]: word to store 9
    ; [rbp - 6]: word to store 32
    push rbp
    mov rbp, rsp
    sub rsp, 8

    mov word [rbp - 2], 5
    mov word [rbp - 4], 9
    mov word [rbp - 6], 32

    fimul word [rbp - 4]
    fidiv word [rbp - 2]
    fiadd word [rbp - 6]

    fstp dword [rsi]

    .done:
        ; Collapse stack and return
        mov rsp, rbp
        pop rbp
        ret

; Convert a 32-bit float to a string
; rdi: pointer to float buffer (4 bytes)
; rsi: pointer to string buffer
; return: the string will be stored in the specified output buffer, and the length will be stored in rax
convert_float_to_string:
    fninit  ; Reset the FPU stack ignoring exceptions

    ; Set up a 24-byte stack
    ; [rbp - 4]: dword integer part (as an int)
    ; [rbp - 8]: dword fractional part (as an int)
    ; [rbp - 10]: word for FPU control 
    ; [rbp - 11]: byte for whether or not float is negative (0 = positive, 1 = negative)
    ; [rbp - 15]: dword to store multiplier for fractional part
    ; [rbp - 23]: qword to store a copy of the original rsi, needed for when converting back to string
    push rbp
    mov rbp, rsp
    sub rsp, 24

    ; Initialise stack
    mov qword [rbp - 8], 0
    mov byte [rbp - 11], 0
    mov byte [rbp - 15], 1
    mov qword [rbp - 23], rsi

    ; To fix a certain number of d.p., we can scale the fractional part by a power of 10
    ; and then multiply the fractional part by that. Then truncate the scaled fractional part
    ; to an integer to get the desired fixed number of d.p.
    mov ecx, 0
    .scale_fractional_part_multiplier:
        cmp ecx, DP
        je .completed_scaling
        imul ebx, dword [rbp - 15], 10
        inc ecx
        mov dword [rbp - 15], ebx
        jmp .scale_fractional_part_multiplier

    .completed_scaling:
    ; Load the float into ST0
    fld dword [rdi]

    ; Check if the float is negative or not
    ftst  ; Check against 0.0
    fstsw ax  ; Store float flags
    sahf  ; Store values in ah to flags
    jnc .positive_float  ; C0 goes to CF after sahf. C0 is only on when st0 < 0.0, so the same for CF. Thus the float is positive or zero if CF is not on
    jz .its_zero  ; C3 is only on when the float equals 0.0. As C3 goes to ZF, if ZF is on, then st0 == 0.0, so directly write '0.0' and ret
    inc byte [rbp - 11]
    mov byte [rsi], CHR_HYPHEN
    fchs  ; Change sign

    .positive_float:
        ; Load ST0 into ST1 as well
        fld st0

        ; Store the integer part

        ; Set FPU to round towards 0
        fstcw word [rbp - 10]
        mov ax, word [rbp - 10]  ; Copy the flag to ax
        and ax, 1111001111111111b  ; Clear RC flag
        or ax,  0000110000000000b  ; Set RC flag to 11b
        mov word [rbp - 10], ax  ; Store the new flag back
        fldcw word [rbp - 10]  ; Store the new flag in the FPU

        frndint  ; Set ST0 to the rounded version
        fist dword [rbp - 4]  ; Store the integer part in ST0 into memory: NOTE ST0 itself remains unchanged 
        fsub st1, st0  ; ST1 -= ST0, now ST1 has only the fractional part
        fstp st0  ; Now ST1 is empty and ST0 contains the fractional part

        ; Store the fractional part

        ; Set FPU to round to nearest
        fstcw word [rbp - 10]
        mov ax, word [rbp - 10]  ; Copy the flag to ax
        and ax, 1111001111111111b  ; Set RC flag to 00b
        mov word [rbp - 10], ax  ; Store the new flag back
        fldcw word [rbp - 10]  ; Store the new flag in the FPU

        fimul dword [rbp - 15]
        frndint  ; Round fractional part scaled so only 2 dp are shown
        fist dword [rbp - 8]  ; Store the fractional part scaled into [rbp - 8]

    ; Now store the integer part to the string
    .add_int_digits_to_string:
        lea rdi, [rbp - 4]
        mov rbx, 0
        mov bl, byte [rbp - 11]
        lea rsi, [rsi + rbx]  ; The buffer to store the integer part starts after the hyphen (if there is one)
        call convert_32_bit_int_to_string

    ; Add the decimal point
    mov rsi, qword [rbp - 23]
    mov rbx, 0
    mov bl, byte [rbp - 11]
    add rbx, rax  ; Have to do this so that there aren't too many registers in the address
    mov byte [rsi + rbx], CHR_POINT  ; rax has the length of the integer part

    .add_frac_digits_to_string:
        lea rdi, [rbp - 8]
        mov rbx, 0
        mov bl, byte [rbp - 11]
        add rbx, rax  ; Have to do this to avoid too many registers
        inc rbx  ; Helps clean up the address expr if we already add 1
        lea rsi, [rsi + rbx]  ; The next byte after the decimal point
        mov r9, rbx
        call convert_32_bit_int_to_string
        add rax, r9  ; The entire length is the length previous length (stored in r9) + the return value (in rax). Get the total length in rax by adding the two

    .done:
        ; Collapse stack and return
        mov rsp, rbp
        pop rbp
        ret

    .its_zero:
        ; Set the string to 0
        mov byte [rsi], CHR_0
        mov byte [rsi + 1], CHR_POINT
        mov byte [rsi + 2], CHR_0 
        jmp .done

