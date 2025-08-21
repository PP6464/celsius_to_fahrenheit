import os

asm_files = list(map(lambda x: x.split(".")[0], os.listdir("./src")))

for file in asm_files:
    filename = file.split(".")[0]
    os.system(f"nasm -felf64 -gdwarf src/{filename}.asm -o ./objects/{filename}.o")


link_command = "ld -o ./executables/program.out "
for file in asm_files:
    filename = file.split(".")[0]
    link_command += f"./objects/{filename}.o "

print(link_command)
os.system(link_command)
