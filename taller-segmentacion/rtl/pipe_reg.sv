// =============================================================================
// pipe_reg.sv - Registro de segmentacion de ancho parametrizable
//
// Un flip-flop D de W bits con tres controles sincronos, en este orden de
// prioridad:
//
//   rst  pone el registro a cero (arranque)
//   clr  pone el registro a cero (burbuja o instruccion matada)  -> FlushD/E
//   en   con en = 0 el registro conserva lo que tiene             -> StallF/D
//
// Los tres hacen falta: sin en no se puede PARAR una etapa, y sin clr no se
// puede meter una BURBUJA. Poner el registro entero a cero es meter un nop:
// con todos los bits de control en cero la instruccion no escribe registros,
// no escribe memoria y no salta.
//
// clr gana sobre en: si alguna vez llegaran juntas una orden de parar y una
// de matar, la instruccion que hay que matar no puede quedarse viva.
// =============================================================================
module pipe_reg #(
    parameter int W = 32
)(
    input  logic         clk,
    input  logic         rst,
    input  logic         en,      // habilitacion: 0 = congelar
    input  logic         clr,     // borrado sincrono: 1 = meter ceros
    input  logic [W-1:0] d,
    output logic [W-1:0] q
);

    always_ff @(posedge clk) begin
        if      (rst) q <= '0;
        else if (clr) q <= '0;
        else if (en)  q <= d;
    end

endmodule
