# Celsius to Fahrenheit
This is a simple application that takes in a celsius temperature (rounded towards zero), and outputs the corresponding Fahrenheit temperature (rounded towards zero). It is written using the NASM assembler.
## Platforms
This only runs on Linux x86_64
## How to run
Run the file `./build.py` to generate the objects and the executable. Then run the file `./executables/program.out` to run the program
## WIP
- Add functionality to work with float inputs too (There is a method to validate floats in `./src/validator.asm` but then actually working with them is a pain so for now only integers)