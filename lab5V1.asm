; grayscale.asm — корректная версия (System V AMD64, nasm -f elf64)
; extern void grayscale_asm(uint8_t *data, int32_t width, int32_t height);

        global  grayscale_asm

        section .text

; rdi = data*, rsi = width, rdx = height
grayscale_asm:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 32              ; 16-байтовое выравнивание + рабочий буфер

        push    rbx
        push    rdi
        push    r11
        push    r12
        push    r13
        push    r14
        push    r15

;        ; -------- сохранить аргументы --------
        mov     r13, rcx             ; r13 = base ptr  (data)
        mov     ebx, edx             ; ebx = width     (non-volatile)
        mov     r12d, r8d            ; r12d = height   (non-volatile)

        ; -------- row_size = ((width*3+3)&~3) --------
        mov     eax, ebx
        imul    eax, 3
        add     eax, 3
        and     eax, -4
        mov     r14d, eax            ; r14d = row_size

        xor     r15d, r15d           ; y = 0
.outer_row:
        cmp     r15d, r12d
        jge     .done

        ; rsi = row_ptr = data + y*row_size
        mov     eax, r14d
        imul    eax, r15d
        lea     rsi, [r13 + rax]
;
        xor     r11d, r11d           ; x = 0
.inner_px:
        cmp     r11d, ebx
        jge     .next_row
;
;        ; rdi = pixel_ptr = row_ptr + x*3
        mov     rdi, r11
        add     rdi, r11
        add     rdi, r11
        add     rdi, rsi
;;
;        ; --- load B,G,R ---
        movzx   eax, byte [rdi]      ; B
        movzx   edx, byte [rdi+1]    ; G
        movzx   ecx, byte [rdi+2]    ; R
;
        imul    eax, 114             ; B*114
        imul    edx, 587             ; G*587
        imul    ecx, 299             ; R*299
        add     eax, edx
        add     eax, ecx
        add     eax, 500             ; +0.5 for rounding

        xor     edx, edx             ; edx:eax / 1000
        mov     ecx, 1000
        div     ecx                  ; eax = gray

        ; --- store gray ---
        mov     [rdi],    al
        mov     [rdi+1],  al
        mov     [rdi+2],  al

        inc     r11d
        jmp     .inner_px

.next_row:
        inc     r15d
        jmp     .outer_row

.done:
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     r11
        pop     rdi
        pop     rbx

        add     rsp, 32
        mov     rsp, rbp
        pop     rbp
        ret
