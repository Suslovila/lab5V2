CC     := gcc
NASM   := nasm

# Уровень оптимизации — можно переопределить при вызове make:
#   make           (будет -O2)
#   make OPT=-O0
#   make OPT=-O1
#   make OPT=-O3
#   make OPT=-Ofast
OPT    ?= -O2

CFLAGS := -Wall -Wextra $(OPT)
LDFLAGS:=

ASM_SRC := lab5V1.asm
ASM_OBJ := gray.o

C_SRC   := main.c
C_OBJ   := main.o

TARGET := lab5.exe

.PHONY: all clean

all: $(TARGET)

# Сборка ассемблера
$(ASM_OBJ): $(ASM_SRC)
	$(NASM) -f win64 $< -o $@

# Сборка C
$(C_OBJ): $(C_SRC)
	$(CC) $(CFLAGS) -c $< -o $@

# Линковка
$(TARGET): $(C_OBJ) $(ASM_OBJ)
	$(CC) $^ $(LDFLAGS) -o $@

clean:
	del /Q *.o $(TARGET) 2>nul || rm -f *.o $(TARGET)
