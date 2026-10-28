// =============================================================================
// riscv_monociclo.sv - El procesador entero       >>> LO ESCRIBEN USTEDES <<<
//
// Aqui no se describe logica nueva: se CONECTAN las cajas que ya existen. Todo
// este archivo son declaraciones, cortes, instancias y cables, y lo escriben
// entero: solo la cabecera del modulo viene hecha.
//
// LOS NOMBRES DE LAS INSTANCIAS NO SON LIBRES. El testbench llega a tus
// registros y a tu memoria por referencia jerarquica, asi que necesita
// encontrarlos exactamente asi:
//
//     register_file  ->  rf          (el testbench lee dut.rf.regs[i])
//     data_memory    ->  dmem        (el testbench lee dut.dmem.mem[i])
//
// El resto los eligen ustedes, pero hay una convencion sugerida mas abajo.
//
// Conexion POR NOMBRE siempre: .puerto (senal). La conexion posicional esta
// prohibida en el curso, porque el dia que alguien anada un puerto todas las
// instancias quedan mal conectadas y ninguna herramienta se queja.
//
// -----------------------------------------------------------------------------
// LA LISTA DE CABLES
//
// Cada fila es una declaracion logic con ese ancho. Los campos de la
// instruccion (opcode ... rd) no salen de ninguna caja: son CORTES de instr,
// y se escriben con assign. No son logica.
//
// Senal         Ancho  Sale de                  Entra a
// ------------  -----  -----------------------  ----------------------------
// pc_actual       32   registro_pc.pc           imem.addr, sumadores, mux_a
// pc_plus4        32   add_pc4.y                mux_pc.d0, mux_res.d10
// pc_plus_imm     32   add_tgt.y                mux_jalr.d0
// pc_target       32   mux_jalr.y               mux_pc.d1
// pc_next         32   mux_pc.y                 registro_pc.pc_next
// instr           32   imem.instr               los campos de abajo, ig
// opcode           7   instr[6:0]               control.opcode
// funct3           3   instr[14:12]             control.funct3, dmem.funct3
// funct7b5         1   instr[30]                control.funct7b5
// rs1              5   instr[19:15]             rf.rs1
// rs2              5   instr[24:20]             rf.rs2
// rd               5   instr[11:7]              rf.rd
// rd1             32   rf.rd1                   mux_a.d0
// rd2             32   rf.rd2                   mux_b.d0, dmem.wd
// imm_ext         32   ig.imm_ext               mux_b.d1, add_tgt.b, mux_res.d11
// src_a           32   mux_a.y                  alu.src_a
// src_b           32   mux_b.y                  alu.src_b
// alu_result      32   alu.alu_result           dmem.addr, mux_res.d00, mux_jalr
// read_data       32   dmem.rd                  mux_res.d01
// result          32   mux_res.y                rf.wd3
// zero/less/less_u 1   alu                      control
// las de control        control                 cada caja
//
// Las senales de control, con sus anchos, son los puertos de salida de
// control_unit: copialas de ahi.
// -----------------------------------------------------------------------------
//
// Las CATORCE instancias, en el orden en que conviene escribirlas:
//
//   pc  add_pc4  imem  control  rf  ig  mux_a  mux_b  alu_i  dmem
//   mux_res  add_tgt  mux_jalr  mux_pc
//
// Las catorce son suyas. Pistas de las que suelen salir mal:
//   - imem y dmem llevan parametros: .DEPTH(IMEM_DEPTH) y .INIT_FILE(INIT_FILE)
//     en imem, .DEPTH(DMEM_DEPTH) en dmem.
//   - mux_jalr elige entre pc_plus_imm y {alu_result[31:1], 1'b0}: jalr pone
//     a cero el bit 0 del destino.
//   - El sumador de PC + 4 recibe la constante 32'd4 en su entrada b.
// =============================================================================
module riscv_monociclo #(
    parameter int IMEM_DEPTH = 256,
    parameter int DMEM_DEPTH = 256,
    parameter     INIT_FILE  = ""
)(
    input logic clk,
    input logic rst,
    input logic en
);

    import riscv_pkg::*;

    // -------------------------------------------------------------------------
    // Los cables del camino de datos
    // -------------------------------------------------------------------------
    logic [31:0] pc_actual;     // registro_pc.pc
    logic [31:0] pc_plus4;      // add_pc4.y
    logic [31:0] pc_plus_imm;   // add_tgt.y
    logic [31:0] pc_target;     // mux_jalr.y
    logic [31:0] pc_next;       // mux_pc.y
    logic [31:0] instr;         // imem.instr
    logic [31:0] rd1, rd2;      // rf.rd1, rf.rd2
    logic [31:0] imm_ext;       // ig.imm_ext
    logic [31:0] src_a, src_b;  // mux_a.y, mux_b.y
    logic [31:0] alu_result;    // alu_i.alu_result
    logic [31:0] read_data;     // dmem.rd
    logic [31:0] result;        // mux_res.y
    logic [31:0] jalr_target;   // {alu_result[31:1], 1'b0}

    // -------------------------------------------------------------------------
    // Los campos de la instruccion: cortes de instr, no logica
    // -------------------------------------------------------------------------
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7b5;
    logic [4:0] rs1, rs2, rd;

    assign opcode   = instr[6:0];
    assign funct3   = instr[14:12];
    assign funct7b5 = instr[30];
    assign rs1      = instr[19:15];
    assign rs2      = instr[24:20];
    assign rd       = instr[11:7];

    // jalr pone a cero el bit 0 del destino
    assign jalr_target = {alu_result[31:1], 1'b0};

    // -------------------------------------------------------------------------
    // Las senales de control y las banderas de la ALU
    // -------------------------------------------------------------------------
    logic       reg_write;
    logic [2:0] imm_src;
    logic       alu_src_a;
    logic       alu_src_b;
    logic       mem_write;
    logic [1:0] result_src;
    logic       branch;
    logic       jump;
    logic       jalr;
    logic [3:0] alu_control;
    logic       pc_src;
    logic       zero, less, less_u;

    // -------------------------------------------------------------------------
    // Las catorce instancias
    // -------------------------------------------------------------------------

    // 1. El contador de programa
    pc registro_pc (
        .clk     (clk),
        .rst     (rst),
        .en      (en),
        .pc_next (pc_next),
        .pc      (pc_actual)
    );

    // 2. PC + 4
    adder add_pc4 (
        .a (pc_actual),
        .b (32'd4),
        .y (pc_plus4)
    );

    // 3. La memoria de instrucciones
    instruction_memory #(
        .DEPTH     (IMEM_DEPTH),
        .INIT_FILE (INIT_FILE)
    ) imem (
        .addr  (pc_actual),
        .instr (instr)
    );

    // 4. La unidad de control
    control_unit control (
        .opcode      (opcode),
        .funct3      (funct3),
        .funct7b5    (funct7b5),
        .zero        (zero),
        .less        (less),
        .less_u      (less_u),
        .reg_write   (reg_write),
        .imm_src     (imm_src),
        .alu_src_a   (alu_src_a),
        .alu_src_b   (alu_src_b),
        .mem_write   (mem_write),
        .result_src  (result_src),
        .branch      (branch),
        .jump        (jump),
        .jalr        (jalr),
        .alu_control (alu_control),
        .pc_src      (pc_src)
    );

    // 5. El banco de registros (el testbench lo busca como "rf")
    register_file rf (
        .clk (clk),
        .we  (reg_write),
        .rs1 (rs1),
        .rs2 (rs2),
        .rd  (rd),
        .wd3 (result),
        .rd1 (rd1),
        .rd2 (rd2)
    );

    // 6. El generador de inmediatos
    imm_gen ig (
        .instr   (instr),
        .imm_src (imm_src),
        .imm_ext (imm_ext)
    );

    // 7. Operando A de la ALU: rs1 o PC (auipc)
    mux2 #(.W (32)) mux_a (
        .d0  (rd1),
        .d1  (pc_actual),
        .sel (alu_src_a),
        .y   (src_a)
    );

    // 8. Operando B de la ALU: rs2 o ImmExt
    mux2 #(.W (32)) mux_b (
        .d0  (rd2),
        .d1  (imm_ext),
        .sel (alu_src_b),
        .y   (src_b)
    );

    // 9. La ALU
    alu alu_i (
        .src_a       (src_a),
        .src_b       (src_b),
        .alu_control (alu_control),
        .alu_result  (alu_result),
        .zero        (zero),
        .less        (less),
        .less_u      (less_u)
    );

    // 10. La memoria de datos (el testbench la busca como "dmem")
    data_memory #(
        .DEPTH (DMEM_DEPTH)
    ) dmem (
        .clk    (clk),
        .we     (mem_write),
        .funct3 (funct3),
        .addr   (alu_result),
        .wd     (rd2),
        .rd     (read_data)
    );

    // 11. Lo que se escribe en rd: ALU / memoria / PC+4 / ImmExt
    mux4 #(.W (32)) mux_res (
        .d00 (alu_result),
        .d01 (read_data),
        .d10 (pc_plus4),
        .d11 (imm_ext),
        .sel (result_src),
        .y   (result)
    );

    // 12. PC + ImmExt: destino de branch y jal
    adder add_tgt (
        .a (pc_actual),
        .b (imm_ext),
        .y (pc_plus_imm)
    );

    // 13. Destino del salto: PC + ImmExt, o rs1 + imm con el bit 0 a cero (jalr)
    mux2 #(.W (32)) mux_jalr (
        .d0  (pc_plus_imm),
        .d1  (jalr_target),
        .sel (jalr),
        .y   (pc_target)
    );

    // 14. El proximo PC
    mux2 #(.W (32)) mux_pc (
        .d0  (pc_plus4),
        .d1  (pc_target),
        .sel (pc_src),
        .y   (pc_next)
    );

endmodule
