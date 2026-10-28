# Taller 1 - Busqueda binaria en RV32I
# Arquitectura de Computadores - UTP
# Solo instrucciones base (sin pseudoinstrucciones).

# ---------------------------------------------------------------
# Arranque: llama a main y se queda quieto con pos en a0
# ---------------------------------------------------------------
_start:
    jal   ra, main
fin:
    jal   x0, fin

# ---------------------------------------------------------------
# int mitad(int lo, int hi)      a0 = lo, a1 = hi  ->  a0
# Hoja: no toca el stack
# ---------------------------------------------------------------
mitad:
    add   a0, a0, a1            # a0 = lo + hi
    srai  a0, a0, 1             # a0 = (lo + hi) >> 1
    jalr  x0, 0(ra)

# ---------------------------------------------------------------
# int elemento(int *A, int i)    a0 = A, a1 = i  ->  a0
# Hoja: no toca el stack
# ---------------------------------------------------------------
elemento:
    slli  t0, a1, 2             # i * 4: indice -> bytes
    add   t0, a0, t0            # direccion de A[i]
    lw    a0, 0(t0)             # a0 = A[i]
    jalr  x0, 0(ra)

# ---------------------------------------------------------------
# int busqueda_binaria(int *A, int lo, int hi, int x)
#   a0 = A, a1 = lo, a2 = hi, a3 = x  ->  a0
#
# Frame de 32 bytes:
#   28(sp) [ ra guardado ]
#   24(sp) [ s0 = A      ]
#   20(sp) [ s1 = lo     ]
#   16(sp) [ s2 = hi     ]
#   12(sp) [ s3 = x      ]
#    8(sp) [ s4 = m      ]
#    4(sp) [ libre       ]
#    0(sp) [ libre       ]
# ---------------------------------------------------------------
busqueda_binaria:
    # ---- PROLOGO ----
    addi  sp, sp, -32
    sw    ra, 28(sp)
    sw    s0, 24(sp)
    sw    s1, 20(sp)
    sw    s2, 16(sp)
    sw    s3, 12(sp)
    sw    s4, 8(sp)

    # ---- CASO BASE: if (lo > hi) return -1 ----
    bge   a2, a1, seguir        # condicion invertida: hi >= lo -> seguir
    addi  a0, x0, -1
    jal   x0, epilogo

seguir:
    addi  s0, a0, 0             # s0 = A   (cruza las llamadas)
    addi  s1, a1, 0             # s1 = lo
    addi  s2, a2, 0             # s2 = hi
    addi  s3, a3, 0             # s3 = x

    # ---- m = mitad(lo, hi) ----
    addi  a0, s1, 0
    addi  a1, s2, 0
    jal   ra, mitad             # <-- AQUI se perderia ra si no se hubiera guardado en el prologo
    addi  s4, a0, 0             # s4 = m   (cruza la llamada a elemento)

    # ---- v = elemento(A, m) ----
    addi  a0, s0, 0
    addi  a1, s4, 0
    jal   ra, elemento          # a0 = v

    # ---- if (v == x) return m ----
    bne   a0, s3, no_igual      # condicion invertida
    addi  a0, s4, 0
    jal   x0, epilogo

no_igual:
    # ---- if (v < x) derecha, else izquierda ----
    bge   a0, s3, izquierda     # condicion invertida: v >= x -> izquierda
    addi  a0, s0, 0             # A
    addi  a1, s4, 1             # m + 1
    addi  a2, s2, 0             # hi
    addi  a3, s3, 0             # x
    jal   ra, busqueda_binaria
    jal   x0, epilogo

izquierda:
    addi  a0, s0, 0             # A
    addi  a1, s1, 0             # lo
    addi  a2, s4, -1            # m - 1
    addi  a3, s3, 0             # x
    jal   ra, busqueda_binaria
                                # cae directo al epilogo

epilogo:                        # UNO SOLO, para los cuatro caminos de salida
    lw    s4, 8(sp)
    lw    s3, 12(sp)
    lw    s2, 16(sp)
    lw    s1, 20(sp)
    lw    s0, 24(sp)
    lw    ra, 28(sp)
    addi  sp, sp, 32
    jalr  x0, 0(ra)

# ---------------------------------------------------------------
# int main(void)   devuelve pos en a0
#
# Frame de 48 bytes:
#   44(sp) [ ra guardado ]
#   40(sp) [ libre, relleno ]
#   36(sp) [ A[9] = 91 ]
#   ...
#    0(sp) [ A[0] = 2  ]
# ---------------------------------------------------------------
main:
    addi  sp, sp, -48
    sw    ra, 44(sp)

    addi  t0, x0, 2
    sw    t0, 0(sp)             # A[0] = 2
    addi  t0, x0, 5
    sw    t0, 4(sp)             # A[1] = 5
    addi  t0, x0, 8
    sw    t0, 8(sp)             # A[2] = 8
    addi  t0, x0, 12
    sw    t0, 12(sp)            # A[3] = 12
    addi  t0, x0, 16
    sw    t0, 16(sp)            # A[4] = 16
    addi  t0, x0, 23
    sw    t0, 20(sp)            # A[5] = 23
    addi  t0, x0, 38
    sw    t0, 24(sp)            # A[6] = 38
    addi  t0, x0, 56
    sw    t0, 28(sp)            # A[7] = 56
    addi  t0, x0, 72
    sw    t0, 32(sp)            # A[8] = 72
    addi  t0, x0, 91
    sw    t0, 36(sp)            # A[9] = 91

    addi  a0, sp, 0             # a0 = A (direccion de A[0])
    addi  a1, x0, 0             # lo = 0
    addi  a2, x0, 9             # hi = 9
    addi  a3, x0, 23            # x  = 23   (cambiar aqui para probar otros)
    jal   ra, busqueda_binaria  # a0 = pos

    lw    ra, 44(sp)
    addi  sp, sp, 48
    jalr  x0, 0(ra)
