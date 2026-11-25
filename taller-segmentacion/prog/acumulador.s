# =============================================================================
# acumulador.s - Un lw seguido de un uso, dentro de un bucle con acumuladores
#
# Si la unidad para el frente pero NO mete la burbuja (falta FlushE), la copia
# de la instruccion dependiente que ya habia pasado a ID/EX se ejecuta, y
# cuando la original avanza se ejecuta otra vez. En un acumulador eso se ve:
# la suma sale de mas.
#
# Paradas esperadas: 3 (una por vuelta)
#
# Estado esperado:
#   x6 = 21  (5 + 7 + 9)          x7 = 3  (vueltas)
#   Mem[0] = 21
# =============================================================================

    addi  x10, x0, 64           # arreglo en Mem[16..18]
    addi  x1, x0, 5
    sw    x1, 0(x10)
    addi  x1, x0, 7
    sw    x1, 4(x10)
    addi  x1, x0, 9
    sw    x1, 8(x10)

    addi  x11, x0, 3            # contador de vueltas
    addi  x6, x0, 0             # acumulador
bucle:
    lw    x5, 0(x10)
    add   x6, x6, x5            # PARADA: usa x5 a distancia 1
    addi  x7, x7, 1             # segundo acumulador
    addi  x10, x10, 4
    addi  x11, x11, -1
    bne   x11, x0, bucle

    sw    x6, 0(x0)             # Mem[0] = 21

fin:
    beq   x0, x0, fin
