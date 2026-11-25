// =============================================================================
// tb_hazard_unit.sv - La tabla de la seccion 12, fila por fila
//
// Incluye la fila que ningun programa puede detectar: ResultSrcE = 11 (lui)
// con dependencia. Con la condicion de Harris & Harris (solo el bit 0) la
// unidad pararia; con los dos bits contra 01, no.
// =============================================================================
`timescale 1ns/1ps

module tb_hazard_unit;

    logic [4:0] rs1D, rs2D, rdE;
    logic [1:0] ResultSrcE;
    logic       PCSrcE;
    logic       StallF, StallD, FlushD, FlushE;

    int pruebas, errores;

    hazard_unit dut (
        .rs1D (rs1D), .rs2D (rs2D), .rdE (rdE),
        .ResultSrcE (ResultSrcE), .PCSrcE (PCSrcE),
        .StallF (StallF), .StallD (StallD), .FlushD (FlushD), .FlushE (FlushE)
    );

    task automatic fila(input logic [4:0] r1, r2, rd, input logic [1:0] rs,
                        input logic pcs,
                        input logic stall, flush_d, flush_e, input string nota);
        rs1D = r1; rs2D = r2; rdE = rd; ResultSrcE = rs; PCSrcE = pcs;
        #1;
        pruebas++;
        if (StallF !== stall || StallD !== stall ||
            FlushD !== flush_d || FlushE !== flush_e) begin
            errores++;
            $display("  FALLO %-34s StallF=%b StallD=%b FlushD=%b FlushE=%b  esperado %b %b %b %b",
                     nota, StallF, StallD, FlushD, FlushE, stall, stall, flush_d, flush_e);
        end
    endtask

    initial begin
        pruebas = 0; errores = 0;

        //   rs1D rs2D rdE ResultSrcE PCSrcE  Stall FlushD FlushE  situacion
        fila(5,   6,   7,  2'b00,     0,      0,    0,     0, "nada que detectar");
        fila(5,   6,   5,  2'b00,     0,      0,    0,     0, "depende de un add");
        fila(5,   6,   5,  2'b01,     0,      1,    0,     1, "load-use por rs1");
        fila(5,   6,   6,  2'b01,     0,      1,    0,     1, "load-use por rs2");
        fila(5,   6,   7,  2'b01,     0,      0,    0,     0, "un lw, pero a otro registro");
        fila(5,   6,   5,  2'b10,     0,      0,    0,     0, "jal: su PC+4 ya existe");
        fila(5,   6,   5,  2'b11,     0,      0,    0,     0, "lui: el bit 0 solo pararia");
        fila(5,   6,   7,  2'b00,     1,      0,    1,     1, "salto tomado");

        // --- Fuera de la tabla ---
        fila(5,   5,   5,  2'b01,     0,      1,    0,     1, "load-use por los dos operandos");
        fila(5,   6,   6,  2'b11,     0,      0,    0,     0, "lui por rs2: tampoco para");

        $display("--------------------------------------------------");
        $display("pruebas: %0d    errores: %0d", pruebas, errores);
        if (errores == 0) $display("tb_hazard_unit: PASS");
        else              $display("tb_hazard_unit: FAIL");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
