# =============================================================================
# x0.s - Instrucciones que escriben en x0, seguidas de lecturas de x0
#
# El banco descarta la escritura, pero la instruccion igual viaja con
# RegWrite = 1 y rd = 0. Si la unidad de forwarding no excluye x0, adelanta
# ese valor sobre cualquier lectura de x0 y x0 deja de valer cero.
#
# Estado esperado (sin la condicion rs != 0, entre parentesis):
#   x2 = 0     (24)           x0 a distancia 1 por A y por B
#   x3 = 5     (19)           x0 a distancia 2 por B
#   x4 = 1     (0x12345001)   lui que escribe x0, distancia 1
#   x0 = 0
# =============================================================================

    addi  x1, x0, 5             # x1 = 5
    addi  x0, x1, 7             # "escribe" 12 en x0: se descarta
    add   x2, x0, x0            # x2 = 0 + 0 = 0
    addi  x0, x1, 9             # "escribe" 14 en x0
    nop
    add   x3, x1, x0            # x3 = 5 + 0 = 5
    lui   x0, 0x12345           # "escribe" 0x12345000 en x0
    addi  x4, x0, 1             # x4 = 0 + 1 = 1

fin:
    beq   x0, x0, fin
