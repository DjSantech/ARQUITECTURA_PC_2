# =============================================================================
# sw_regwrite.s - Instrucciones que NO escriben registros, pero cuyos bits
#                 11..7 parecen un rd
#
# sw x1, 8(x2) lleva el desplazamiento 8 en los bits 11..7: si la unidad de
# forwarding no mira RegWrite, lo lee como "escribo x8" y adelanta la
# direccion calculada (108) en lugar del contenido de x8 (5).
#
# Lo mismo con un beq NO tomado de desplazamiento +8: sus bits 11..7 tambien
# valen 8, y su "resultado" de ALU es la resta x1 - x0 = 33.
#
# Estado esperado (sin la condicion RegWrite, entre parentesis):
#   x9  = 5    (108)   sw a distancia 1, por A
#   x10 = 5    (108)   sw a distancia 2, por B
#   x11 = 5    (33)    beq no tomado a distancia 1
#   Mem[27] = 33        (108 / 4 = 27)
# =============================================================================

    addi  x8, x0, 5             # x8 = 5: el registro que hay que leer
    addi  x2, x0, 100           # base
    addi  x1, x0, 33            # dato
    nop
    nop

    sw    x1, 8(x2)             # Mem[108] = 33   (bits 11..7 = 8)
    add   x9, x8, x0            # x9 = 5

    sw    x1, 8(x2)             # otra vez, ahora a distancia 2
    nop
    add   x10, x0, x8           # x10 = 5

    beq   x1, x0, sigue         # no se toma (33 != 0); offset +8 -> bits 11..7 = 8
    add   x11, x8, x0           # x11 = 5
sigue:

fin:
    beq   x0, x0, fin
