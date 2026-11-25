# =============================================================================
# acumulador_reordenado.s - El mismo calculo que acumulador.s, reordenado
#
# Las dos instrucciones independientes del cuerpo del bucle (el contador de
# vueltas y el avance del puntero) se suben entre el lw y su uso. El lw queda
# a distancia 3 del add y el forwarding/banco lo cubren sin parar.
#
# Es lo que hace un compilador. El resultado es identico; solo cambia el
# numero de ciclos.
#
# Paradas esperadas: 0
#
# Estado esperado: igual que acumulador.s
#   x6 = 21   x7 = 3   Mem[0] = 21
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
    addi  x7, x7, 1             # independiente: sube aqui
    addi  x10, x10, 4           # independiente: sube aqui
    add   x6, x6, x5            # x5 a distancia 3: sin parada
    addi  x11, x11, -1
    bne   x11, x0, bucle

    sw    x6, 0(x0)             # Mem[0] = 21

fin:
    beq   x0, x0, fin
