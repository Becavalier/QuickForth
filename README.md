# Forthress
A forth dialect with its VM. 

***Can only be used under Linux X86-64***.

### Compile

```bash
nasm -f elf64 vm.asm -o vm.o && ld vm.o -o vm
```
### Run

```bash
./vm
```
