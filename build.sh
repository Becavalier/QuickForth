#!/bin/sh
cd ./src && nasm -O0 -f elf64 vm.asm -o vm.o && ld vm.o -o vm && ./vm
