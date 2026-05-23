; ISR_KB.ASM — ISR personalizado para IRQ1 (teclado) 
; Compila: nasm -f bin ISR_KB.ASM -o ISR_KB.COM 
 
[BITS 16] 
[ORG 0x100] 
 
section .data 
contador    DW 0          ; número de teclas atendidas 
MAX_KEYS    EQU 5 
old_isr     DD 0          ; almacena SEG:OFF del handler original 
msg_tecla   DB 0Dh, 0Ah, "Tecla detectada por ISR propio$" 
msg_fin     DB 0Dh, 0Ah, "ISR restaurado. Fin del programa.$" 
 
section .text 
start:
    MOV AX, 3509h
    INT 21h
    MOV [old_isr],   BX
    MOV [old_isr+2], ES

    PUSH DS
    PUSH CS
    POP DS
    MOV DX, mi_isr_chain
    MOV AX, 2509h
    INT 21h
    POP DS

    STI

.esperar:
    MOV AX, [contador]
    CMP AX, MAX_KEYS
    JL  .esperar

    CLI
    LDS DX, [old_isr]
    MOV AX, 2509h
    INT 21h
    STI

    PUSH CS
    POP DS
    MOV AH, 09h
    MOV DX, msg_fin
    INT 21h

    MOV AH, 4Ch
    INT 21h

; ── ISR ────────────────────────────────────────────────────────────
mi_isr_chain:
    PUSH AX
    PUSH DX
    PUSH DS

    IN  AL, 60h             ; leer scancode
    TEST AL, 80h            ; break code?
    JNZ .encadenar          ; si es break, saltar directo al original

    ; solo make code — código propio
    PUSH CS
    POP DS

    INC WORD [contador]

    MOV AH, 09h
    MOV DX, msg_tecla
    INT 21h

    POP DS
    POP DX
    POP AX
    PUSHF
    CALL FAR [old_isr]
    IRET

.encadenar:
    POP DS
    POP DX
    POP AX
    PUSHF
    CALL FAR [old_isr]
    IRET