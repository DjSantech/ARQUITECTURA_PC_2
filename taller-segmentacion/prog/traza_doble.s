# =============================================================================
# traza_doble.s - La traza de la seccion 7 de la guia (doble hazard)
#
# Las cuatro primeras instrucciones solo cargan x1..x4; asi el primer add
# entra a IF en el ciclo 5, como en la guia. En c9 el tercer add esta en EX,
# el segundo en MEM y el primero en WB: gana EX/MEM.
#
# Estado esperado: x5 = 7 (3 + 4), x6 = 8 (7 + 1)
# =============================================================================

    addi  x1, x0, 1
    addi  x2, x0, 2
    addi  x3, x0, 3
    addi  x4, x0, 4
    add   x5, x1, x2            # escribe x5 = 3
    add   x5, x3, x4            # vuelve a escribir x5 = 7
    add   x6, x5, x1            # lee x5: el de EX/MEM -> x6 = 8

fin:
    beq   x0, x0, fin
