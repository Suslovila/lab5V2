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

section .text
global grayscale_asm

; void grayscale_asm(uint8_t *data, int32_t width, int32_t height)
; Arguments (System V AMD64):
;   rdi = pointer to pixel data buffer
;   rsi = width (pixels per row)
;   rdx = height (number of scanlines)
;
grayscale_asm:
    ; preserve callee-saved registers we'll use (rbx, r12)
    push    rbx
    push    r12

    ; copy width and height to temporaries
    mov     r8d, esi        ; r8d = width
    mov     r9d, edx        ; r9d = height

    ; compute row_size = (width * 3 + 3) & ~3
    mov     r10d, r8d       ; r10d = width
    imul    r10d, 3         ; r10d = width * 3
    add     r10d, 3         ; r10d += 3 for rounding up
    and     r10d, -4        ; align down to multiple of 4

    xor     r11d, r11d      ; y = 0 (r11d)
.outer_loop:
    cmp     r11d, r9d       ; while y < height
    jge     .done

    ; row_ptr = data + y * row_size
    mov     rax, r10        ; rax = row_size
    imul    rax, r11        ; rax = row_size * y
    add     rax, rdi        ; rax = data + offset
    mov     rcx, rax        ; rcx = row_ptr

    xor     r12d, r12d      ; x = 0 (r12d)
.inner_loop:
    cmp     r12d, r8d       ; while x < width
    jge     .next_row

    ; pixel_ptr = row_ptr + x * 3

    ; фикс
    mov     rax, r12
    shl     rax, 1      ; rax = r12 * 2
    add     rax, r12    ; rax = r12 * 3
    add     rax, rcx    ; rax = row_ptr + x * 3

    ; load components: B, G, R
    movzx   eax, byte [rax]     ; eax = B
    movzx   ebx, byte [rax+1]   ; ebx = G
    movzx   ecx, byte [rax+2]   ; ecx = R

    ; compute gray = (299*R + 587*G + 114*B + 500) / 1000
    imul    ecx, 299             ; ecx = R*299
    imul    ebx, 587             ; ebx = G*587
    imul    eax, 114             ; eax = B*114
    add     ecx, ebx             ; ecx += G*587
    add     ecx, eax             ; ecx += B*114
    add     ecx, 500             ; rounding
    mov     ebx, 1000            ; divisor
    xor     edx, edx             ; clear edx for DIV
    div     ebx                  ; eax = gray (quotient)

    ; store gray back to B, G, R
    mov     byte [rax], al
    mov     byte [rax+1], al
    mov     byte [rax+2], al

    inc     r12                 ; x++
    jmp     .inner_loop

.next_row:
    inc     r11                 ; y++
    jmp     .outer_loop

.done:
    ; restore registers and return
    pop     r12
    pop     rbx
    ret
