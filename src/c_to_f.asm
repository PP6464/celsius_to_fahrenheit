%define SYS_EXIT 60
%define EXIT_SUCCESS 0
%define EXIT_ERROR 1
%define NEWLINE 10
%define INPUT_BUFFER_SIZE 10
%define OUTPUT_BUFFER_SIZE 15

%define VALID 1
%define INVALID 0

section .bss
    input: resb INPUT_BUFFER_SIZE
    temperature_celsius: resb 4
    temperature_fahrenheit: resb 4
    output: resb OUTPUT_BUFFER_SIZE

section .text

global _start
extern read_from_stdin
extern print
extern println
extern println_error
extern validate_for_float
extern celsius_to_fahrenheit
extern convert_string_to_float
extern convert_float_to_string

_start:
    ; print input prompt
    lea rdi, [enter_celsius]
    call print

    ; Read the user input
    mov rdi, INPUT_BUFFER_SIZE
    lea rsi, [input]
    call read_from_stdin

    ; Validate input
    lea rdi, [input]
    call validate_for_float
    cmp rax, INVALID
    je .invalid

    ; Convert input to float
    ; Input already in rdi
    lea rsi, [temperature_celsius]
    call convert_string_to_float

    ; C to F
    lea rdi, [temperature_celsius]
    lea rsi, [temperature_fahrenheit]
    call celsius_to_fahrenheit

    ; Convert output to string
    lea rdi, [temperature_fahrenheit]
    lea rsi, [output]
    call convert_float_to_string

    ; Print the output text
    lea rdi, [fahrenheit_output]
    call print

    ; Print the Fahrenheit output
    lea rdi, [output]
    call println

    ; Exit process successfully
    mov rax, SYS_EXIT
    mov rdi, EXIT_SUCCESS
    syscall

    .invalid:
        lea rdi, [invalid_input]
        call println_error
        jmp .exit_with_error

    .exit_with_error:
        ; For if there is an error
        mov rax, SYS_EXIT
        mov rdi, EXIT_ERROR
        syscall

section .data
    enter_celsius: db "Enter temperature in Celsius: ", NEWLINE
    invalid_input: db "Invalid input. Closing the program...", NEWLINE
    fahrenheit_output: db "The temperature in Fahrenheit is: ", NEWLINE
