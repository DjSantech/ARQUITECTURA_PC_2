# =============================================================================
# traza_load_use.s - La traza de la seccion 10 de la guia (load-use)
#
# Cinco instrucciones de preparacion: el lw entra a IF en el ciclo 6, como en
# la guia. El add para un ciclo (c9) y el lw de detras tambien se queda quieto.
#
# Estado esperado: x5 = 42, x6 = 84, x7 = 42
# =============================================================================

    addi  x10, x0, 64
    addi  x1, x0, 42
    sw    x1, 0(x10)
    nop
    nop
    lw    x5, 0(x10)
    add   x6, x5, x5            # parada de un ciclo, despues MEM/WB -> EX
    lw    x7, 0(x10)

fin:
    beq   x0, x0, fin
