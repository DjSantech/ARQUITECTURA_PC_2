# =============================================================================
# doble_escritura.s - Dos escrituras seguidas al mismo registro y una lectura
#
# Cuando la tercera instruccion esta en EX, la segunda esta en MEM y la
# primera en WB: las dos condiciones de forwarding se cumplen a la vez. Tiene
# que ganar EX/MEM, la mas reciente. Con la prioridad invertida el resultado
# es plausible y equivocado (el valor de la primera escritura).
#
# Estado esperado:
#   x6 = 2   (invertido daria 1)
#   x8 = 4   (invertido daria 3)     por el operando B
#   x9 = 60
#   Mem[0] = 60 (invertido daria 30)  el dato de un sw, con las dos en vuelo
# =============================================================================

    addi  x5, x0, 1             # escribe x5 = 1
    addi  x5, x0, 2             # vuelve a escribir x5 = 2
    add   x6, x5, x0            # lee x5 por A: x6 = 2

    addi  x7, x0, 3             # escribe x7 = 3
    addi  x7, x0, 4             # vuelve a escribir x7 = 4
    add   x8, x0, x7            # lee x7 por B: x8 = 4

    addi  x9, x0, 30
    add   x9, x9, x9            # x9 = 60 (la segunda depende de la primera)
    sw    x9, 0(x0)             # Mem[0] = 60: dato con las dos en vuelo

fin:
    beq   x0, x0, fin
