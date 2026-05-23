; MASK_KB.ASM — Enmascarar/desenmascarar IRQ1 con el PIC 8259A 
; Compila: nasm -f bin MASK_KB.ASM -o MASK_KB.COM 
 
[BITS 16] 
[ORG 0x100] 

section .data 
msg_mask   DB "IRQ1 enmascarado (teclado deshabilitado)...$" 
msg_unmask DB 0Dh, 0Ah, "IRQ1 restaurado.$" 
 
section .text 
start:
    PUSH CS
    POP DS                  ; fix 1: DS = CS para acceder a los strings

    ; Leer IMR actual y guardar
    IN  AL, 21h
    PUSH AX

    ; Enmascarar IRQ1 (bit 1 del IMR)
    OR  AL, 02h
    OUT 21h, AL

    MOV AH, 09h
    MOV DX, msg_mask
    INT 21h

    ; Esperar ~3 segundos (18.2 ticks/s ≈ 55 ticks)
    MOV AH, 00h
    INT 1Ah                 ; CX:DX = ticks actuales
    MOV BX, DX
    ADD BX, 55

.wait:
    MOV AH, 00h
    INT 1Ah
    CMP DX, BX
    JB  .wait               ; fix 2: JB sin signo en lugar de JL

    ; Restaurar IMR original
    POP AX
    OUT 21h, AL

    MOV AH, 09h
    MOV DX, msg_unmask
    INT 21h

    MOV AH, 4Ch
    INT 21h