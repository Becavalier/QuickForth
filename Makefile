vm: vm.o cmath.so
	ld --dynamic-linker=/lib64/ld-linux-x86-64.so.2 \
		./build/vm.o \
		./build/cmath.so \
		-o ./build/vm

vm.o:
	nasm -i./src \
		-O3 \
		-f elf64 \
		./src/vm.asm \
		-o ./build/vm.o

cmath.so:
	clang -O3 \
		-fPIC \
		-nostdlib \
		-shared \
		./src/lib/cmath.c \
		-o ./build/cmath.so   

clean:
	rm ./build/*
