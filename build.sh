#!/bin/sh
cd src && nasm -f elf64 vm.asm -o vm.o && ld vm.o -o vm && ./vm
