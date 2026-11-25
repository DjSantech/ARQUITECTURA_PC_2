# =============================================================================
# lui_jal.s - Que valor se adelanta: instrucciones que escriben en rd algo que
#             no paso por la ALU
#
# lui escribe el inmediato (ResultSrc = 11) y jal/jalr escriben PC+4
# (ResultSrc = 10). Si EX/MEM solo transporta la salida de la ALU, un lui
# seguido de un uso de su rd adelanta basura: para lui la ALU suma dos
# registros que salen de bits del inmediato.
#
# Estado esperado:
#   x6  = 0x12345000   lui a distancia 1 por A
#   x8  = 0xABCDE000   lui a distancia 2 por B
#   x10 = 0x00000020   auipc a distancia 1 (este si pasa por la ALU)
#   x11 = 0x0000002C   jal: PC+4 de la direccion 0x28
#   x12 = 0            la instruccion detras del jal no deja rastro
#   x13 = 0x0000002C   uso de x11 en el destino (distancia 3: el banco)
#   x14 = 0x00000040   jalr: PC+4 de la direccion 0x3C
#   x16 = 0x00000041   uso del PC+4 de jalr (distancia 3)
# =============================================================================

    lui   x5, 0x12345           # 0x00
    add   x6, x5, x0            # 0x04  x6 = 0x12345000
    lui   x7, 0xABCDE           # 0x08
    nop                         # 0x0C
    add   x8, x0, x7            # 0x10  x8 = 0xABCDE000
    nop                         # 0x14
    nop                         # 0x18
    nop                         # 0x1C
    auipc x9, 0                 # 0x20  x9 = 0x20
    add   x10, x9, x0           # 0x24  x10 = 0x20
    jal   x11, destino          # 0x28  x11 = 0x2C
    addi  x12, x0, 99           # 0x2C  matada por el salto
destino:
    add   x13, x11, x0          # 0x30  x13 = 0x2C
    auipc x15, 0                # 0x34  x15 = 0x34
    addi  x15, x15, 16          # 0x38  x15 = 0x44 (direccion de "tras")
    jalr  x14, 0(x15)           # 0x3C  x14 = 0x40 ... salta a 0x44
    addi  x12, x0, 98           # 0x40  matada por el salto
tras:
    addi  x16, x14, 1           # 0x44  x16 = 0x41

fin:
    beq   x0, x0, fin
