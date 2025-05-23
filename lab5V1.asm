; grayscale.asm — NASM x86-64 implementation of BMP grayscale conversion routine
; Integrate with C main (lab5.c):
; 1) Remove or comment-out the static "grayscale_c" in lab5.c
; 2) Declare extern:
;      extern void grayscale_asm(uint8_t *data, int32_t width, int32_t height);
; 3) Replace call to grayscale_c with grayscale_asm(pixels, width, height);
;
; Build and link:
;   nasm -f elf64 grayscale.asm -o grayscale.o
;   gcc -no-pie -Wall -Wextra -O2 lab5.c grayscale.o -o lab5
global grayscale_asm

extern printf, scanf, fopen, fprintf, fclose
extern fabs, cos

section .data
    ; constant for integer division
    div1000:    dd 1000
    fmt_errarg: db      "Usinnnng %d", 10,0

section .text


; void grayscale_asm(uint8_t *data, int32_t width, int32_t height)
    ; System V AMD64: rdi = data ptr, rsi = width, rdx = height

grayscale_asm:
    ; save callee-saved registers


    push    rbx
    push    r12

    ; copy args to callee-saved or temp regs
    mov     r8d, esi        ; r8d = width
    mov     r9d, edx        ; r9d = height

    ; compute row_size = (width*3 + 3) & ~3
    mov     r10d, r8d       ; r10d = width
    imul    r10d, 3         ; r10d = width * 3
    add     r10d, 3         ; +3 for rounding up
    and     r10d, -4        ; align down to multiple of 4

    xor     r11d, r11d      ; y = 0
.outer_loop:
    cmp     r11d, r9d       ; if y >= height
    jge     .done

    ; row_ptr = data + y * row_size
    mov     rax, r10        ; rax = row_size
    imul    rax, r11        ; rax = row_size * y
    add     rax, rdi        ; rax = data + offset
    mov     rcx, rax        ; rcx = row_ptr

    xor     r12d, r12d      ; x = 0
.inner_loop:
    cmp     r12d, r8d       ; if x >= width
    jge     .next_row

    ; pixel_ptr = rcx + x*3 → in RSI
    mov     rax, r12        ; rax = x
    shl     rax, 1          ; rax = x*2
    add     rax, r12        ; rax = x*3
    add     rax, rcx        ; rax = row_ptr + x*3
    mov     rsi, rax        ; rsi = pixel_ptr

    ; load B, G, R components
    movzx   eax, byte [rsi]     ; eax = B
    movzx   edx, byte [rsi+1]   ; edx = G
    movzx   ebx, byte [rsi+2]   ; ebx = R

    ; compute gray = (299*R + 587*G + 114*B + 500) / 1000
    imul    ebx, 299            ; ebx = R*299
    imul    edx, 587            ; edx = G*587
    imul    eax, 114            ; eax = B*114
    add     ebx, edx            ; ebx += G*587
    add     ebx, eax            ; ebx += B*114
    add     ebx, 500            ; rounding
    mov     eax, ebx            ; numerator → eax
    xor     edx, edx            ; edx:eax → dividend
    div     dword [rel div1000] ; eax = gray

    ; store gray back into B, G, R
    mov     [rsi], al
    mov     [rsi+1], al
    mov     [rsi+2], al

    inc     r12d                ; x++
    jmp     .inner_loop

.next_row:
    inc     r11d                ; y++
    jmp     .outer_loop

.done:
    pop     r12
    pop     rbx
    ret
