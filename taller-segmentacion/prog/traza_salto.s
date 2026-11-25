# =============================================================================
# traza_salto.s - La traza de la seccion 14 de la guia (salto tomado)
#
# En c6 el beq esta en EX y decide: FlushD y FlushE matan las dos addi de
# detras, y en c7 entra la del destino.
#
# Estado esperado: x3 = 3, x4 = 7, x30 = 0, x31 = 0
# =============================================================================

    addi  x1, x0, 3
    addi  x2, x0, 3
    add   x3, x1, x0
    beq   x3, x2, destino
    addi  x30, x0, 99
    addi  x31, x0, 99
destino:
    addi  x4, x0, 7

fin:
    beq   x0, x0, fin
