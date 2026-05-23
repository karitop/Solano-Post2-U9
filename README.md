# Solano-Post2-U9

# Unidad 9: Entrada y Salida Avanzados

# Prerrequisitos

- DOSBox 0.74 o superior
- NASM 2.x
- Editor de texto

---

# Programas
**ISR_KB.ASM: ISR personalizado para IRQ1**
El PIC 8259A maestro traduce la línea IRQ1 (teclado) al vector de interrupción INT 09h. Normalmente DOS maneja esta interrupción internamente, pero es posible reemplazar ese handler temporalmente instalando una rutina propia.
El programa guarda la dirección del handler original usando INT 21h AH=35h, que devuelve en ES:BX el vector actual de INT 09h. Luego instala el ISR propio con INT 21h AH=25h, apuntando el vector a la rutina mi_isr.
Cada vez que se presiona una tecla, el ISR lee el scancode del puerto 60h y verifica el bit 7: si está en 1 es un break code (tecla soltada) y se ignora; si está en 0 es un make code (tecla presionada) y se muestra el mensaje y se incrementa el contador. Al finalizar el ISR se envía el EOI al PIC maestro con OUT 20h, AL (valor 20h al puerto 20h) para habilitar futuras interrupciones, y se retorna con IRET.
Al alcanzar 5 pulsaciones el programa restaura el handler original con INT 21h AH=25h usando la dirección guardada previamente, y termina.

**Compilar y ejecutar:**
```
nasm -f bin ISR_KB.ASM -o ISR_KB.COM
ISR_KB
```

<img width="646" height="189" alt="C1" src="https://github.com/user-attachments/assets/38b0af60-02f7-48c9-a8de-5570340c67f4" />

---

**MASK_KB.ASM: Enmascaramiento del IRQ1 con el PIC 8259A**
El IMR (Interrupt Mask Register) del PIC 8259A maestro reside en el puerto 21h. Cada bit controla una línea IRQ: bit en 1 deshabilita la IRQ, bit en 0 la habilita. El bit 1 corresponde al IRQ1 (teclado).
El programa lee el IMR actual con IN AL, 21h y guarda el valor original en el stack. Luego activa el bit 1 con OR AL, 02h y escribe el nuevo valor con OUT 21h, AL, deshabilitando el teclado. Durante aproximadamente 3 segundos (55 ticks del timer BIOS a 18.2 ticks/segundo) las pulsaciones de tecla no generan ningún evento visible, aunque los scancodes se acumulan internamente en el buffer del 8042. Al terminar el retardo se restaura el IMR original y el teclado vuelve a funcionar normalmente.

**Compilar y ejecutar:**
```
nasm -f bin MASK_KB.ASM -o MASK_KB.COM
MASK_KB
```

<img width="642" height="107" alt="C2" src="https://github.com/user-attachments/assets/1a4ad1a1-0996-4742-9502-c892498fdfc8" />

---

**ISR_CHAIN.ASM: Encadenamiento del ISR (Chaining)**
El encadenamiento consiste en instalar un ISR propio que ejecuta su código y luego transfiere el control al handler original, en lugar de reemplazarlo completamente. Esto es útil cuando se quiere agregar comportamiento sin interferir con el procesamiento normal del sistema.
El programa instala mi_isr_chain como handler de INT 09h de la misma forma que ISR_KB. La diferencia está al final del ISR: en lugar de enviar el EOI y retornar con IRET, se simula una interrupción hacia el handler original usando PUSHF seguido de CALL FAR [old_isr]. El PUSHF es necesario porque el handler original espera encontrar los flags en el stack tal como los dejaría una instrucción INT. El handler original se encarga de leer el scancode, procesar la tecla y enviar el EOI al PIC.
El resultado es que el ISR propio registra la pulsación y muestra el mensaje, mientras el sistema sigue respondiendo normalmente al teclado (el eco de DOS sigue funcionando).

**Compilar y ejecutar:**
```
nasm -f bin ISR_CHAIN.ASM -o ISR_CHAIN.COM
ISR_CHAIN
```

<img width="641" height="184" alt="C3" src="https://github.com/user-attachments/assets/b687a25a-687a-4cd8-b8df-0f67bf1c0fee" />
