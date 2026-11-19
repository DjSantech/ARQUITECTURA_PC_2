// =============================================================================
// tb_forwarding_unit.sv - La tabla de la seccion 6, fila por fila
//
// La tabla es la especificacion, escrita para un operando. Aqui se aplica dos
// veces: una con el registro bajo prueba en rs1E (se mira ForwardAE) y otra en
// rs2E (se mira ForwardBE). En cada pasada el otro operando lleva un registro
// que no coincide con nada, y su salida tiene que ser 00: asi se comprueba
// tambien que los dos multiplexores son independientes.
// =============================================================================
`timescale 1ns/1ps

module tb_forwarding_unit;

    logic [4:0] rs1E, rs2E, rdM, rdW;
    logic       RegWriteM, RegWriteW;
    logic [1:0] ForwardAE, ForwardBE;

    int pruebas, errores;

    forwarding_unit dut (
        .rs1E (rs1E), .rs2E (rs2E), .rdM (rdM), .rdW (rdW),
        .RegWriteM (RegWriteM), .RegWriteW (RegWriteW),
        .ForwardAE (ForwardAE), .ForwardBE (ForwardBE)
    );

    // El registro del "otro" operando: no coincide con ningun rd de la tabla
    localparam logic [4:0] OTRO = 5'd20;

    task automatic fila(input logic [4:0] rs, rd_m, input logic rw_m,
                        input logic [4:0] rd_w, input logic rw_w,
                        input logic [1:0] esperado, input string nota);
        // --- Pasada 1: el registro bajo prueba es rs1 ---
        rs1E = rs;  rs2E = OTRO;
        rdM = rd_m; RegWriteM = rw_m;
        rdW = rd_w; RegWriteW = rw_w;
        #1;
        pruebas++;
        if (ForwardAE !== esperado || ForwardBE !== 2'b00) begin
            errores++;
            $display("  FALLO [A] %-38s ForwardAE=%b ForwardBE=%b  esperado %b/00",
                     nota, ForwardAE, ForwardBE, esperado);
        end

        // --- Pasada 2: el registro bajo prueba es rs2 ---
        rs1E = OTRO; rs2E = rs;
        #1;
        pruebas++;
        if (ForwardBE !== esperado || ForwardAE !== 2'b00) begin
            errores++;
            $display("  FALLO [B] %-38s ForwardAE=%b ForwardBE=%b  esperado 00/%b",
                     nota, ForwardAE, ForwardBE, esperado);
        end
    endtask

    initial begin
        pruebas = 0; errores = 0;

        //   rsE  rdM RWM  rdW RWW  salida   situacion
        fila(5,   7,  1,   8,  1,   2'b00, "nadie escribe ese registro");
        fila(5,   5,  1,   8,  1,   2'b10, "la de delante escribe x5");
        fila(5,   7,  1,   5,  1,   2'b01, "la de dos por delante escribe x5");
        fila(5,   5,  1,   5,  1,   2'b10, "las dos: gana la mas cercana");
        fila(5,   5,  0,   8,  1,   2'b00, "coincide, pero no escribe (sw)");
        fila(5,   7,  1,   5,  0,   2'b00, "coincide, pero no escribe (branch)");
        fila(0,   0,  1,   0,  1,   2'b00, "el operando es x0");
        fila(31,  31, 1,   8,  1,   2'b10, "x31: se comparan los cinco bits");

        // --- Tres filas mas, fuera de la tabla ---
        fila(5,   5,  0,   5,  1,   2'b01, "EX/MEM no escribe: cae a MEM/WB");
        fila(0,   0,  1,   8,  1,   2'b00, "x0 solo en MEM");
        fila(21,  5,  1,   8,  1,   2'b00, "21 vs 5: difieren solo en bit 4");

        // --- Los dos operandos a la vez, de sitios distintos ---
        rs1E = 5'd5; rs2E = 5'd6;
        rdM  = 5'd5; RegWriteM = 1'b1;
        rdW  = 5'd6; RegWriteW = 1'b1;
        #1;
        pruebas++;
        if (ForwardAE !== 2'b10 || ForwardBE !== 2'b01) begin
            errores++;
            $display("  FALLO A de EX/MEM y B de MEM/WB a la vez: %b/%b", ForwardAE, ForwardBE);
        end

        $display("--------------------------------------------------");
        $display("pruebas: %0d    errores: %0d", pruebas, errores);
        if (errores == 0) $display("tb_forwarding_unit: PASS");
        else              $display("tb_forwarding_unit: FAIL");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
