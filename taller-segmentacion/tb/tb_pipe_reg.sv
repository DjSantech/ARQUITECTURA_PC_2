// =============================================================================
// tb_pipe_reg.sv - El registro de segmentacion: carga, habilitacion, borrado
//
// Comprueba los tres puertos que la guia exige (seccion 18, fase 1) y la
// prioridad entre ellos: rst > clr > en.
// =============================================================================
`timescale 1ns/1ps

module tb_pipe_reg;

    logic        clk, rst, en, clr;
    logic [7:0]  d, q;

    int pruebas, errores;

    pipe_reg #(.W (8)) dut (
        .clk (clk), .rst (rst), .en (en), .clr (clr), .d (d), .q (q)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic comprobar(input string nota, input logic [7:0] esperado);
        pruebas++;
        if (q !== esperado) begin
            errores++;
            $display("  FALLO %-40s q=0x%02h  esperado=0x%02h", nota, q, esperado);
        end
    endtask

    // Aplica entradas, da un flanco y comprueba
    task automatic ciclo(input logic r, e, c, input logic [7:0] dato,
                         input string nota, input logic [7:0] esperado);
        rst = r; en = e; clr = c; d = dato;
        @(posedge clk); #1;
        comprobar(nota, esperado);
    endtask

    initial begin
        pruebas = 0; errores = 0;

        ciclo(1, 1, 0, 8'hAA, "reset pone a cero",                 8'h00);
        ciclo(0, 1, 0, 8'h3C, "en=1: carga d",                     8'h3C);
        ciclo(0, 1, 0, 8'h5A, "en=1: carga el siguiente",          8'h5A);
        ciclo(0, 0, 0, 8'hFF, "en=0: se congela (stall)",          8'h5A);
        ciclo(0, 0, 0, 8'h11, "en=0: sigue congelado",             8'h5A);
        ciclo(0, 1, 1, 8'h77, "clr=1: burbuja (flush)",            8'h00);
        ciclo(0, 1, 0, 8'h77, "tras el flush vuelve a cargar",     8'h77);
        ciclo(0, 0, 1, 8'h99, "clr gana sobre en=0",               8'h00);
        ciclo(0, 1, 0, 8'hC3, "carga otra vez",                    8'hC3);
        ciclo(1, 0, 0, 8'h12, "rst gana sobre en=0",               8'h00);

        $display("--------------------------------------------------");
        $display("pruebas: %0d    errores: %0d", pruebas, errores);
        if (errores == 0) $display("tb_pipe_reg: PASS");
        else              $display("tb_pipe_reg: FAIL");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
