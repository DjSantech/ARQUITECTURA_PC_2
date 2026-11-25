# =============================================================================
# load_use.s - Un lw seguido de un uso de su rd: por rs1, por rs2, como dato
#              de un store y como direccion de otro load
#
# Cada uso a distancia 1 de un lw obliga a una parada de exactamente un ciclo.
# Sin la unidad de riesgos, el valor leido llega tarde y la instruccion usa
# el contenido viejo del registro (aqui, 0).
#
# Paradas esperadas: 4
#
# Estado esperado (sin deteccion, entre parentesis):
#   x6  = 25    (0)     uso por rs1
#   x8  = -7    (0)     uso por rs2
#   Mem[18] = 25 (0)    uso como dato de un sw
#   x14 = 7     (Mem[0] = 0)   uso como direccion de un lw
# =============================================================================

    addi  x10, x0, 64           # base del arreglo: 64 = Mem[16]
    addi  x1, x0, 25
    sw    x1, 0(x10)            # Mem[16] = 25
    addi  x2, x0, 7
    sw    x2, 4(x10)            # Mem[17] = 7
    addi  x3, x0, 128
    sw    x3, 12(x10)           # Mem[19] = 128
    sw    x2, 0(x3)             # Mem[32] = 7

    lw    x5, 0(x10)            # x5 = 25
    add   x6, x5, x0            # PARADA. rs1 = x5 -> x6 = 25

    lw    x7, 4(x10)            # x7 = 7
    sub   x8, x0, x7            # PARADA. rs2 = x7 -> x8 = -7

    lw    x9, 0(x10)            # x9 = 25
    sw    x9, 8(x10)            # PARADA. dato del sw -> Mem[18] = 25

    lw    x13, 12(x10)          # x13 = 128
    lw    x14, 0(x13)           # PARADA. direccion -> x14 = Mem[32] = 7

fin:
    beq   x0, x0, fin
