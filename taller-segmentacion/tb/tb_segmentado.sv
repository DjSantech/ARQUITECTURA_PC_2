// =============================================================================
// tb_segmentado.sv - El procesador segmentado contra el monociclo
//
// Cada programa corre a la vez en DOS procesadores: el segmentado de este
// taller y el monociclo del Taller 2. El monociclo ejecuta una instruccion
// por ciclo, sin solapamiento: es la "ejecucion instruccion a instruccion"
// contra la que la guia pide comparar. Al final se comprueban tres cosas:
//
//   1. Valores esperados escritos a mano (los del encabezado de cada .s).
//   2. Estado completo igual al del monociclo: los 32 registros y las 256
//      palabras de la memoria de datos.
//   3. Ciclos. El segmentado tiene que tardar exactamente
//
//          ciclos_mono + 4 + paradas + 2 * saltos_tomados
//
//      4 es el llenado del pipeline, cada parada load-use cuesta 1 y cada
//      salto tomado 2. Si sobra un ciclo, hay una parada de mas; si falta,
//      algo se esta saltando una etapa. Y para los programas donde se sabe
//      cuantas paradas debe haber (load_use, load_indep, acumulador), se
//      comprueba el numero exacto: es lo unico que delata una parada de mas.
//
// "Ciclos" es el ciclo en que la instruccion de "fin:" (el bucle infinito)
// termina por primera vez: en el monociclo, cuando se ejecuta; en el
// segmentado, cuando sale de WB.
// =============================================================================
`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// pareja - un programa en los dos procesadores, con sus contadores
// -----------------------------------------------------------------------------
module pareja #(
    parameter INIT_FILE = ""
)(
    input logic clk,
    input logic rst,
    input logic en
);

    riscv_monociclo  #(.INIT_FILE (INIT_FILE)) mono (.clk (clk), .rst (rst), .en (en));
    riscv_segmentado #(.INIT_FILE (INIT_FILE)) seg  (.clk (clk), .rst (rst), .en (en));

    logic [31:0] dir_fin;      // direccion del bucle "fin: beq x0,x0,fin"
    int ciclo;
    int ciclos_mono;           // 0 = todavia no llega a fin
    int ciclos_seg;
    int paradas;               // ciclos con StallF = 1
    int saltos;                // saltos tomados (PCSrcE = 1)

    // La direccion de fin: la primera instruccion que salta a si misma
    // (beq x0,x0,0 = 0x00000063  o  jal x0,0 = 0x0000006F)
    initial begin
        dir_fin = 32'hFFFF_FFFF;
        #1;
        for (int i = 255; i >= 0; i--)
            if (seg.imem.mem[i] == 32'h0000_0063 || seg.imem.mem[i] == 32'h0000_006F)
                dir_fin = i * 4;
    end

    // En cada flanco se mira el estado del ciclo que termina, que es el
    // ciclo numero (ciclo + 1).
    always_ff @(posedge clk) begin
        if (rst) begin
            ciclo       <= 0;
            ciclos_mono <= 0;
            ciclos_seg  <= 0;
            paradas     <= 0;
            saltos      <= 0;
        end else begin
            ciclo <= ciclo + 1;

            if (ciclos_mono == 0 && mono.pc_actual == dir_fin)
                ciclos_mono <= ciclo + 1;

            if (ciclos_seg == 0) begin
                if (seg.E.pc == dir_fin)
                    ciclos_seg <= ciclo + 3;          // EX ahora, WB dos despues
                else begin
                    if (seg.StallF) paradas <= paradas + 1;
                    if (seg.PCSrcE) saltos  <= saltos  + 1;
                end
            end
        end
    end

    // Diferencias de estado contra el monociclo
    function automatic int diferencias(input string nombre);
        int n = 0;
        for (int i = 0; i < 32; i++)
            if (seg.rf.regs[i] !== mono.rf.regs[i]) begin
                n++;
                $display("  FALLO [%-21s] x%0d: segmentado=0x%08h  monociclo=0x%08h",
                         nombre, i, seg.rf.regs[i], mono.rf.regs[i]);
            end
        for (int i = 0; i < 256; i++)
            if (seg.dmem.mem[i] !== mono.dmem.mem[i]) begin
                n++;
                $display("  FALLO [%-21s] Mem[%0d]: segmentado=0x%08h  monociclo=0x%08h",
                         nombre, i, seg.dmem.mem[i], mono.dmem.mem[i]);
            end
        return n;
    endfunction

endmodule


// -----------------------------------------------------------------------------
// tb_segmentado
// -----------------------------------------------------------------------------
module tb_segmentado;

    localparam int CICLOS = 800;

    logic clk;
    logic rst;
    logic en;

    int pruebas;
    int errores;

    // --- Regresion del Taller 2 ---
    pareja #(.INIT_FILE ("prog/humo.hex"))                  p_humo       (.clk (clk), .rst (rst), .en (en));
    pareja #(.INIT_FILE ("prog/completo.hex"))              p_completo   (.clk (clk), .rst (rst), .en (en));
    pareja #(.INIT_FILE ("prog/bytes.hex"))                 p_bytes      (.clk (clk), .rst (rst), .en (en));
    // --- Los casos de la seccion 19 ---
    pareja #(.INIT_FILE ("prog/fwd_ab.hex"))                p_fwd_ab     (.clk (clk), .rst (rst), .en (en));
    pareja #(.INIT_FILE ("prog/doble_escritura.hex"))       p_doble      (.clk (clk), .rst (rst), .en (en));
    pareja #(.INIT_FILE ("prog/x0.hex"))                    p_x0         (.clk (clk), .rst (rst), .en (en));
    pareja #(.INIT_FILE ("prog/sw_regwrite.hex"))           p_sw         (.clk (clk), .rst (rst), .en (en));
    pareja #(.INIT_FILE ("prog/lui_jal.hex"))               p_lui        (.clk (clk), .rst (rst), .en (en));
    pareja #(.INIT_FILE ("prog/load_use.hex"))              p_load_use   (.clk (clk), .rst (rst), .en (en));
    pareja #(.INIT_FILE ("prog/load_indep.hex"))            p_load_indep (.clk (clk), .rst (rst), .en (en));
    pareja #(.INIT_FILE ("prog/salto.hex"))                 p_salto      (.clk (clk), .rst (rst), .en (en));
    pareja #(.INIT_FILE ("prog/acumulador.hex"))            p_acum       (.clk (clk), .rst (rst), .en (en));
    pareja #(.INIT_FILE ("prog/acumulador_reordenado.hex")) p_acum_r     (.clk (clk), .rst (rst), .en (en));
    // --- El programa del Taller 1 ---
    pareja #(.INIT_FILE ("prog/busqueda_binaria.hex"))      p_busqueda   (.clk (clk), .rst (rst), .en (en));

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic comprobar(input string programa, input string nota,
                             input logic [31:0] obtenido, input logic [31:0] esperado);
        pruebas++;
        if (obtenido !== esperado) begin
            errores++;
            $display("  FALLO [%-21s] %-36s obtenido=0x%08h  esperado=0x%08h",
                     programa, nota, obtenido, esperado);
        end
    endtask

    // Una fila de la tabla de ciclos, con sus tres comprobaciones
    task automatic resumen(input string programa, input int mono, input int seg,
                           input int par, input int sal, input int difs);
        int esperado;
        esperado = mono + 4 + par + 2 * sal;

        pruebas++;
        if (mono == 0 || seg == 0) begin
            errores++;
            $display("  FALLO [%-21s] no llego a fin en %0d ciclos", programa, CICLOS);
        end

        pruebas++;
        if (difs != 0) errores++;      // las diferencias ya se imprimieron

        pruebas++;
        if (seg != esperado) begin
            errores++;
            $display("  FALLO [%-21s] ciclos=%0d, el modelo da %0d+4+%0d+2*%0d=%0d",
                     programa, seg, mono, par, sal, esperado);
        end

        $display("  %-23s %6d %6d %8d %7d    %5.2f",
                 programa, mono, seg, par, sal, real'(seg) / real'(mono));
    endtask

    `define FILA(P, NOMBRE) \
        resumen(NOMBRE, P.ciclos_mono, P.ciclos_seg, P.paradas, P.saltos, P.diferencias(NOMBRE))

    initial begin
        $dumpfile("build/tb_segmentado.vcd");
        $dumpvars(0, tb_segmentado.p_completo);

        pruebas = 0;
        errores = 0;

        en  = 1'b1;
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;

        repeat (CICLOS) @(posedge clk);
        #1;

        // =====================================================================
        // 1. Valores esperados, programa por programa
        // =====================================================================

        // ---- humo.s ----
        comprobar("humo", "x1 = 5",   p_humo.seg.rf.regs[1],  32'd5);
        comprobar("humo", "x2 = 10",  p_humo.seg.rf.regs[2],  32'd10);
        comprobar("humo", "x3 = 15",  p_humo.seg.rf.regs[3],  32'd15);
        comprobar("humo", "Mem[0] = 15", p_humo.seg.dmem.mem[0], 32'd15);

        // ---- completo.s (los mismos valores que tb_cpu del Taller 2) ----
        comprobar("completo", "ra tras jal",          p_completo.seg.rf.regs[1],  32'h0000004C);
        comprobar("completo", "x2 = 10",              p_completo.seg.rf.regs[2],  32'd10);
        comprobar("completo", "x3 = 15",              p_completo.seg.rf.regs[3],  32'd15);
        comprobar("completo", "x4 = 5",               p_completo.seg.rf.regs[4],  32'd5);
        comprobar("completo", "x5 = 0",               p_completo.seg.rf.regs[5],  32'd0);
        comprobar("completo", "x6 = 15",              p_completo.seg.rf.regs[6],  32'd15);
        comprobar("completo", "x7 = 15",              p_completo.seg.rf.regs[7],  32'd15);
        comprobar("completo", "x8 = 1",               p_completo.seg.rf.regs[8],  32'd1);
        comprobar("completo", "x9 = 15 (lw)",         p_completo.seg.rf.regs[9],  32'd15);
        comprobar("completo", "Mem[0] = 15",          p_completo.seg.dmem.mem[0], 32'd15);
        comprobar("completo", "branch no tomado",     p_completo.seg.rf.regs[10], 32'd1);
        comprobar("completo", "branch tomado",        p_completo.seg.rf.regs[11], 32'd2);
        comprobar("completo", "x12 = 3",              p_completo.seg.rf.regs[12], 32'd3);
        comprobar("completo", "lui",                  p_completo.seg.rf.regs[13], 32'h12345000);
        comprobar("completo", "jal + jalr",           p_completo.seg.rf.regs[14], 32'd40);
        comprobar("completo", "sltu",                 p_completo.seg.rf.regs[15], 32'd1);

        // ---- bytes.s ----
        comprobar("bytes", "0xDEADBEEF",   p_bytes.seg.rf.regs[2],  32'hDEADBEEF);
        comprobar("bytes", "lb",           p_bytes.seg.rf.regs[3],  32'hFFFFFFEF);
        comprobar("bytes", "lbu",          p_bytes.seg.rf.regs[4],  32'h000000EF);
        comprobar("bytes", "lh",           p_bytes.seg.rf.regs[5],  32'hFFFFBEEF);
        comprobar("bytes", "lhu",          p_bytes.seg.rf.regs[6],  32'h0000BEEF);
        comprobar("bytes", "sb",           p_bytes.seg.rf.regs[8],  32'hDEAD55EF);
        comprobar("bytes", "sh",           p_bytes.seg.rf.regs[10], 32'h012355EF);
        comprobar("bytes", "lhu alta",     p_bytes.seg.rf.regs[11], 32'h00000123);

        // ---- fwd_ab.s: distancia 1 y 2, operando A y B ----
        comprobar("fwd_ab", "A d2, B d1",          p_fwd_ab.seg.rf.regs[3],  32'd7);
        comprobar("fwd_ab", "A d1, B d2",          p_fwd_ab.seg.rf.regs[4],  32'd4);
        comprobar("fwd_ab", "solo B, distancia 1", p_fwd_ab.seg.rf.regs[6],  -32'sd20);
        comprobar("fwd_ab", "solo B, distancia 2", p_fwd_ab.seg.rf.regs[8],  -32'sd30);
        comprobar("fwd_ab", "solo A, distancia 1", p_fwd_ab.seg.rf.regs[10], 32'd40);
        comprobar("fwd_ab", "solo A, distancia 2", p_fwd_ab.seg.rf.regs[12], 32'd50);
        comprobar("fwd_ab", "distancia 3 (banco)", p_fwd_ab.seg.rf.regs[16], 32'd198);
        comprobar("fwd_ab", "mismo reg. por A y B", p_fwd_ab.seg.rf.regs[18], 32'd12);
        comprobar("fwd_ab", "dato de sw, dist. 1", p_fwd_ab.seg.dmem.mem[0], 32'd77);
        comprobar("fwd_ab", "dato de sw, dist. 2", p_fwd_ab.seg.dmem.mem[1], 32'd88);

        // ---- doble_escritura.s: prioridad ----
        comprobar("doble_escritura", "gana EX/MEM por A",  p_doble.seg.rf.regs[6],  32'd2);
        comprobar("doble_escritura", "gana EX/MEM por B",  p_doble.seg.rf.regs[8],  32'd4);
        comprobar("doble_escritura", "x9 = 60",            p_doble.seg.rf.regs[9],  32'd60);
        comprobar("doble_escritura", "gana EX/MEM en sw",  p_doble.seg.dmem.mem[0], 32'd60);

        // ---- x0.s ----
        comprobar("x0", "x0 a dist. 1 por A y B", p_x0.seg.rf.regs[2], 32'd0);
        comprobar("x0", "x0 a dist. 2 por B",     p_x0.seg.rf.regs[3], 32'd5);
        comprobar("x0", "lui x0 a dist. 1",       p_x0.seg.rf.regs[4], 32'd1);
        comprobar("x0", "x0 sigue en cero",       p_x0.seg.rf.regs[0], 32'd0);

        // ---- sw_regwrite.s ----
        comprobar("sw_regwrite", "sw a dist. 1 (rd falso 8)", p_sw.seg.rf.regs[9],  32'd5);
        comprobar("sw_regwrite", "sw a dist. 2 (rd falso 8)", p_sw.seg.rf.regs[10], 32'd5);
        comprobar("sw_regwrite", "beq no tomado (rd falso)",  p_sw.seg.rf.regs[11], 32'd5);
        comprobar("sw_regwrite", "Mem[27] = 33",              p_sw.seg.dmem.mem[27], 32'd33);

        // ---- lui_jal.s: que valor se adelanta ----
        comprobar("lui_jal", "lui a dist. 1",        p_lui.seg.rf.regs[6],  32'h12345000);
        comprobar("lui_jal", "lui a dist. 2",        p_lui.seg.rf.regs[8],  32'hABCDE000);
        comprobar("lui_jal", "auipc a dist. 1",      p_lui.seg.rf.regs[10], 32'h00000020);
        comprobar("lui_jal", "jal: PC+4",            p_lui.seg.rf.regs[11], 32'h0000002C);
        comprobar("lui_jal", "ranuras de jal/jalr",  p_lui.seg.rf.regs[12], 32'd0);
        comprobar("lui_jal", "uso de PC+4 de jal",   p_lui.seg.rf.regs[13], 32'h0000002C);
        comprobar("lui_jal", "jalr: PC+4",           p_lui.seg.rf.regs[14], 32'h00000040);
        comprobar("lui_jal", "uso de PC+4 de jalr",  p_lui.seg.rf.regs[16], 32'h00000041);

        // ---- load_use.s ----
        comprobar("load_use", "uso por rs1",          p_load_use.seg.rf.regs[6],  32'd25);
        comprobar("load_use", "uso por rs2",          p_load_use.seg.rf.regs[8],  -32'sd7);
        comprobar("load_use", "uso como dato de sw",  p_load_use.seg.dmem.mem[18], 32'd25);
        comprobar("load_use", "uso como direccion",   p_load_use.seg.rf.regs[14], 32'd7);
        comprobar("load_use", "paradas = 4",          p_load_use.paradas, 32'd4);

        // ---- load_indep.s: no debe parar ----
        comprobar("load_indep", "lw a distancia 2",   p_load_indep.seg.rf.regs[7],  32'd12);
        comprobar("load_indep", "lw a distancia 3",   p_load_indep.seg.rf.regs[12], 32'd11);
        comprobar("load_indep", "lui a dist. 1",      p_load_indep.seg.rf.regs[14], 32'h00001000);
        comprobar("load_indep", "x15 = 0x1001",       p_load_indep.seg.rf.regs[15], 32'h00001001);
        comprobar("load_indep", "jal: PC+4",          p_load_indep.seg.rf.regs[17], 32'h00000040);
        comprobar("load_indep", "paradas = 0",        p_load_indep.paradas, 32'd0);

        // ---- salto.s ----
        comprobar("salto", "destino del beq",       p_salto.seg.rf.regs[4],  32'd7);
        comprobar("salto", "ranura 1 del beq",      p_salto.seg.rf.regs[30], 32'd0);
        comprobar("salto", "ranura 2 del beq (sw)", p_salto.seg.dmem.mem[0], 32'd0);
        comprobar("salto", "no tomado: x5",         p_salto.seg.rf.regs[5],  32'd5);
        comprobar("salto", "no tomado: x6",         p_salto.seg.rf.regs[6],  32'd6);
        comprobar("salto", "ranuras del jal",       p_salto.seg.rf.regs[29] | p_salto.seg.rf.regs[28], 32'd0);
        comprobar("salto", "ranuras del jalr",      p_salto.seg.rf.regs[27] | p_salto.seg.rf.regs[26], 32'd0);
        comprobar("salto", "destino del jalr",      p_salto.seg.rf.regs[9],  32'd9);
        comprobar("salto", "bucle: 5 vueltas",      p_salto.seg.rf.regs[11], 32'd10);
        comprobar("salto", "detras del bne: 1 vez", p_salto.seg.rf.regs[12], 32'd1);
        comprobar("salto", "tras el bucle",         p_salto.seg.rf.regs[13], 32'd13);
        comprobar("salto", "saltos tomados = 7",    p_salto.saltos, 32'd7);

        // ---- acumulador.s ----
        comprobar("acumulador", "suma = 21",     p_acum.seg.rf.regs[6],  32'd21);
        comprobar("acumulador", "vueltas = 3",   p_acum.seg.rf.regs[7],  32'd3);
        comprobar("acumulador", "Mem[0] = 21",   p_acum.seg.dmem.mem[0], 32'd21);
        comprobar("acumulador", "paradas = 3",   p_acum.paradas, 32'd3);

        // ---- acumulador_reordenado.s ----
        comprobar("acumulador_reordenado", "suma = 21",   p_acum_r.seg.rf.regs[6], 32'd21);
        comprobar("acumulador_reordenado", "vueltas = 3", p_acum_r.seg.rf.regs[7], 32'd3);
        comprobar("acumulador_reordenado", "paradas = 0", p_acum_r.paradas, 32'd0);

        // ---- busqueda_binaria.s (Taller 1) ----
        comprobar("busqueda_binaria", "a0 = 5 (posicion de 23)", p_busqueda.seg.rf.regs[10], 32'd5);
        comprobar("busqueda_binaria", "sp vuelve a 1024",        p_busqueda.seg.rf.regs[2],  32'd1024);

        // =====================================================================
        // 2 y 3. Estado igual al monociclo, y ciclos
        // =====================================================================
        $display("");
        $display("  programa                 mono    seg  paradas  saltos  seg/mono");
        $display("  ----------------------- ------ ------ -------- ------- ---------");
        `FILA(p_humo,       "humo");
        `FILA(p_completo,   "completo");
        `FILA(p_bytes,      "bytes");
        `FILA(p_fwd_ab,     "fwd_ab");
        `FILA(p_doble,      "doble_escritura");
        `FILA(p_x0,         "x0");
        `FILA(p_sw,         "sw_regwrite");
        `FILA(p_lui,        "lui_jal");
        `FILA(p_load_use,   "load_use");
        `FILA(p_load_indep, "load_indep");
        `FILA(p_salto,      "salto");
        `FILA(p_acum,       "acumulador");
        `FILA(p_acum_r,     "acumulador_reordenado");
        `FILA(p_busqueda,   "busqueda_binaria");
        $display("");

        $display("--------------------------------------------------");
        $display("pruebas: %0d    errores: %0d", pruebas, errores);
        if (errores == 0) $display("tb_segmentado: PASS");
        else              $display("tb_segmentado: FAIL");
        $display("--------------------------------------------------");

        $finish;
    end

endmodule
