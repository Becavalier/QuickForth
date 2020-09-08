#!/bin/sh
nasm -f elf64 vm.asm -o vm.o && ld vm.o -o vm && ./vm
