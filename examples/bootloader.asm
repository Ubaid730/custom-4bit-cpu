; ============================================================
; VERITON-16 BOOTLOADER — stage 0 (ROM) with inline kernel handoff
; Build & run:
;   python3 scripts/assembler.py examples/bootloader.asm build/bootloader.v
;   ./scripts/simulate.sh tb_virt build/bootloader.v
; Expected virtual-console output: "BOOT\nKN\nEW\n" then LEDs show 0xF0
; ============================================================

boot:
        LI   R15, 0xFFF8      ; GPIO/LED base pointer
        LI   R14, 0xFFFA      ; UART data port pointer

        ; --- print banner "BOOT" ---
        LI   R1, 0x42         ; 'B'
        STORE R1, [R14]
        LI   R1, 0x4F         ; 'O'
        STORE R1, [R14]
        LI   R1, 0x4F         ; 'O'
        STORE R1, [R14]
        LI   R1, 0x54         ; 'T'
        STORE R1, [R14]
        LI   R1, 0x0A         ; '\n'
        STORE R1, [R14]

        ; --- boot LED pattern ---
        LI   R1, 0x0F
        STORE R1, [R15]

        ; --- hand off to kernel (real loaders would COPY a staged
        ;     image from ROM->RAM first; here the kernel is linked
        ;     into the same ROM for simplicity) ---
        CALL kernel

        HALT                  ; should never return here

kernel:
        PUSH R14              ; save context (demonstrates convention)
        PUSH R15

        ; print "NEW\n" from the kernel
        LI   R1, 0x4E         ; 'N'
        STORE R1, [R14]
        LI   R1, 0x45         ; 'E'
        STORE R1, [R14]
        LI   R1, 0x57         ; 'W'
        STORE R1, [R14]
        LI   R1, 0x0A
        STORE R1, [R14]

        ; kernel owns the LEDs now
        LI   R1, 0xF0
        STORE R1, [R15]

        POP  R15              ; restore context
        POP  R14
        RET                   ; return to bootloader -> HALT
