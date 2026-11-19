// =============================================================================
// forwarding_unit.sv - Unidad de forwarding (vive en EX)
//
// Decide, para cada operando de la instruccion que esta en EX, de donde sale
// el valor bueno:
//
//   00  del banco de registros (distancia 3 o mas, o ninguna dependencia)
//   10  de EX/MEM  (la instruccion de delante:    distancia 1)
//   01  de MEM/WB  (la de dos posiciones delante: distancia 2)
//
// No ve datos: solo NUMEROS de registro y dos bits de RegWrite. Es
// combinacional pura, sin reloj y sin estado.
//
// Cada condicion tiene tres partes, y ninguna sobra:
//
//   1. rsE != 0     x0 nunca se adelanta. Un nop (addi x0,x0,0) o cualquier
//                   instruccion que escriba en x0 se anuncia como "escribo
//                   x0"; sin esta condicion x0 deja de valer cero.
//
//   2. RegWrite     la de delante tiene que escribir de verdad. En un sw o un
//                   beq los bits 11..7 son inmediato, no rd: un sw con
//                   desplazamiento 8 se anunciaria como escritura a x8.
//
//   3. rsE == rd    los cinco bits.
//
// Y el ORDEN es la prioridad: EX/MEM se pregunta primero. Si las dos de
// delante escriben el mismo registro, la mas cercana es la mas reciente y la
// de MEM/WB ya esta obsoleta.
//
// ForwardBE es la misma logica cambiando rs1E por rs2E. Va escrita completa,
// no derivada: es el multiplexor que tambien alimenta el dato de los stores.
// =============================================================================
module forwarding_unit (
    input  logic [4:0] rs1E,        // registros fuente de la que esta en EX
    input  logic [4:0] rs2E,
    input  logic [4:0] rdM,         // destino de la que va una posicion delante
    input  logic [4:0] rdW,         // destino de la que va dos posiciones delante
    input  logic       RegWriteM,
    input  logic       RegWriteW,
    output logic [1:0] ForwardAE,   // selector del multiplexor del operando A
    output logic [1:0] ForwardBE    // selector del multiplexor del operando B
);

    import pipeline_pkg::*;

    // ---- Operando A (rs1) ----------------------------------------------------
    always_comb begin
        if      ((rs1E != 5'd0) && RegWriteM && (rs1E == rdM)) ForwardAE = FWD_MEM;
        else if ((rs1E != 5'd0) && RegWriteW && (rs1E == rdW)) ForwardAE = FWD_WB;
        else                                                   ForwardAE = FWD_RF;
    end

    // ---- Operando B (rs2) ----------------------------------------------------
    always_comb begin
        if      ((rs2E != 5'd0) && RegWriteM && (rs2E == rdM)) ForwardBE = FWD_MEM;
        else if ((rs2E != 5'd0) && RegWriteW && (rs2E == rdW)) ForwardBE = FWD_WB;
        else                                                   ForwardBE = FWD_RF;
    end

endmodule
