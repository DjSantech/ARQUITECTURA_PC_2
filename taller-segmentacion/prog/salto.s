# =============================================================================
# salto.s - Saltos tomados con instrucciones detras que dejarian rastro
#
# El salto se decide en EX; para entonces las dos de detras ya estan en IF e
# ID. FlushD y FlushE las matan. Si falta cualquiera de las dos, esas
# instrucciones se ejecutan y dejan rastro en registros o en memoria.
#
# Estado esperado:
#   x4  = 7     el destino del beq tomado
#   x30 = 0     ranura 1 del beq (seria 99)
#   Mem[0] = 0  ranura 2 del beq: un sw (seria 3)
#   x5  = 5     x6 = 6   un salto NO tomado no mata nada
#   x29 = 0     x28 = 0  ranuras del jal
#   x27 = 0     x26 = 0  ranuras del jalr
#   x9  = 9     destino del jalr
#   x11 = 10    el cuerpo del bucle corre 5 veces
#   x12 = 1     la instruccion detras del bne del bucle: solo a la salida
#   x13 = 13    tras el bucle
# =============================================================================

    addi  x1, x0, 3
    addi  x2, x0, 3
    add   x3, x1, x0            # x3 = 3
    beq   x3, x2, destino       # se toma
    addi  x30, x0, 99           # ranura 1: no debe ejecutarse
    sw    x2, 0(x0)             # ranura 2: no debe escribir memoria
destino:
    addi  x4, x0, 7

    # --- Un salto no tomado: las dos de detras SI se ejecutan ---
    bne   x3, x2, fin
    addi  x5, x0, 5
    addi  x6, x0, 6

    # --- jal: incondicional, tambien mata dos ---
    jal   x0, tras_jal
    addi  x29, x0, 99
    addi  x28, x0, 99
tras_jal:

    # --- jalr: el destino viene de la ALU (auipc a distancia 1) ---
    auipc x20, 0                # x20 = direccion de este auipc
    jalr  x0, 16(x20)           # salta 4 instrucciones adelante
    addi  x27, x0, 99
    addi  x26, x0, 99
    addi  x9, x0, 9             # destino del jalr

    # --- Un bucle: bne hacia atras, tomado 4 veces ---
    addi  x10, x0, 5
bucle:
    addi  x11, x11, 2
    addi  x10, x10, -1
    bne   x10, x0, bucle
    addi  x12, x12, 1           # detras del bne: solo cuenta la salida
    addi  x13, x0, 13

fin:
    beq   x0, x0, fin
