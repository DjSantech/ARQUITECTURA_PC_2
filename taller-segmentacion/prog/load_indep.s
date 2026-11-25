# =============================================================================
# load_indep.s - Casos en los que la unidad de riesgos NO debe parar
#
# Una parada de mas no cambia el resultado, solo cuesta un ciclo. Por eso
# este programa no se juzga por los registros sino por el NUMERO DE PARADAS,
# que el testbench cuenta: tiene que ser 0.
#
#   - lw, una instruccion independiente y el uso: distancia 2, lo cubre el
#     forwarding desde MEM/WB.
#   - lw seguido de una instruccion que lee OTROS registros.
#   - lui seguido de un uso de su rd: ResultSrcE = 11. Si la condicion mira
#     solo el bit 0 de ResultSrcE (la version de Harris & Harris), aqui para.
#   - jal: ResultSrcE = 10, su PC+4 ya existe en EX.
#
# Paradas esperadas: 0
#
# Estado esperado:
#   x7 = 12   x12 = 11   x14 = 0x00001000   x15 = 0x00001001
#   x16 = 0x40   x17 = 0x40
# =============================================================================

    addi  x10, x0, 64
    addi  x1, x0, 11
    sw    x1, 0(x10)            # Mem[16] = 11
    nop
    nop

    lw    x5, 0(x10)            # x5 = 11
    addi  x6, x0, 1             # independiente
    add   x7, x5, x6            # uso a distancia 2 -> 12, sin parada

    lw    x8, 0(x10)            # x8 = 11
    add   x9, x1, x6            # lee x1 y x6, no x8 -> sin parada
    addi  x11, x0, 3
    add   x12, x8, x0           # distancia 3 -> 11

    lui   x13, 0x1              # ResultSrc = 11
    add   x14, x13, x0          # uso a distancia 1 -> 0x1000, sin parada
    addi  x15, x14, 1           # 0x1001

    jal   x16, sigue            # 0x3C: x16 = 0x40
sigue:
    add   x17, x16, x0          # el destino es la siguiente: x17 = 0x40

fin:
    beq   x0, x0, fin
