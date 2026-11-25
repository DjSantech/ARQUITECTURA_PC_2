# =============================================================================
# fwd_ab.s - Dependencias a distancia 1, 2 y 3, por el operando A y por el B
#
# Cada bloque deja un registro con un valor que SOLO sale bien si el operando
# vino del sitio correcto. Si falta ForwardBE (o esta mal), fallan x3, x6, x8,
# Mem[0] y Mem[1]; si falta ForwardAE, fallan x4, x10, x12.
#
# Estado esperado:
#   x3  = 7      x4  = 4      x6  = -20    x8  = -30    x10 = 40
#   x12 = 50     x16 = 198    x18 = 12     Mem[0] = 77  Mem[1] = 88
# =============================================================================

    addi  x1, x0, 10            # x1 = 10
    addi  x2, x0, 3             # x2 = 3
    sub   x3, x1, x2            # A a distancia 2, B a distancia 1  -> 7
    sub   x4, x3, x2            # A a distancia 1, B a distancia 2  -> 4
    nop
    nop
    nop

    # --- Solo el operando B ---
    addi  x5, x0, 20
    sub   x6, x0, x5            # B a distancia 1 -> -20
    addi  x7, x0, 30
    nop
    sub   x8, x0, x7            # B a distancia 2 -> -30

    # --- Solo el operando A ---
    addi  x9, x0, 40
    add   x10, x9, x0           # A a distancia 1 -> 40
    addi  x11, x0, 50
    nop
    add   x12, x11, x0          # A a distancia 2 -> 50

    # --- El dato de un store tambien es el operando B ---
    addi  x13, x0, 77
    sw    x13, 0(x0)            # dato a distancia 1 -> Mem[0] = 77
    addi  x14, x0, 88
    nop
    sw    x14, 4(x0)            # dato a distancia 2 -> Mem[1] = 88

    # --- Distancia 3: la resuelve el banco (escribe y lee en el mismo ciclo)
    addi  x15, x0, 99
    nop
    nop
    add   x16, x15, x15         # -> 198

    # --- El mismo registro por los dos operandos ---
    addi  x17, x0, 6
    add   x18, x17, x17         # -> 12

fin:
    beq   x0, x0, fin
