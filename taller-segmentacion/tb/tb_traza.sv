// =============================================================================
// tb_traza.sv - Imprime, ciclo a ciclo, que instruccion hay en cada etapa
//
// No comprueba nada: produce la materia prima de los diagramas de pipeline
// (IF ID EX MEM WB por ciclo). tools/traza.py la convierte en la tabla.
//
// Cada instruccion buscada recibe un numero de secuencia al entrar en IF. Ese
// numero viaja por una copia "en sombra" del pipeline que obedece las mismas
// senales StallF, StallD, FlushD y FlushE que el procesador real. -1 = burbuja
// o etapa vacia.
//
// El programa se elige al lanzar la simulacion:
//     vsim -c -G INIT_FILE=prog/traza_load_use.hex work.tb_traza
// =============================================================================
`timescale 1ns/1ps

module tb_traza;

    parameter INIT_FILE = "prog/traza_load_use.hex";
    parameter int CICLOS = 24;

    logic clk, rst, en;

    riscv_segmentado #(.INIT_FILE (INIT_FILE)) dut (.clk (clk), .rst (rst), .en (en));

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Copia en sombra del pipeline: numeros de secuencia
    int seqF, seqD, seqE, seqM, seqW;

    always_ff @(posedge clk) begin
        if (rst) begin
            seqF <= 0;
            seqD <= -1; seqE <= -1; seqM <= -1; seqW <= -1;
        end else begin
            if (!dut.StallF) seqF <= seqF + 1;
            if      (dut.FlushD)  seqD <= -1;
            else if (!dut.StallD) seqD <= seqF;
            seqE <= dut.FlushE ? -1 : seqD;
            seqM <= seqE;
            seqW <= seqM;
        end
    end

    initial begin
        en  = 1'b1;
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;

        // A mitad de cada ciclo: el estado del ciclo, ya estable
        for (int c = 1; c <= CICLOS; c++) begin
            @(negedge clk);
            $display("TRAZA %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
                     c, seqF, dut.PCF, seqD, seqE, seqM, seqW,
                     dut.StallF, dut.FlushD, dut.FlushE, dut.ForwardAE, dut.ForwardBE);
            @(posedge clk);
        end
        $finish;
    end

endmodule
