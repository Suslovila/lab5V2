CC    = gcc
NASM  = nasm

CFLAGS  = -Wall -Wextra -O2         # для релиза; для анализа — 00/01/...
LDFLAGS =

all: lab5

gray.o: lab5V1.asm
	$(NASM) -f win64 $< -o $@

main.o: main.c
	$(CC) $(CFLAGS) -c $< -o $@

lab5: main.o gray.o
	$(CC) $^ $(LDFLAGS) -o $@

clean:
	rm -f *.o lab5