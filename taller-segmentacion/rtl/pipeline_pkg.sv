// =============================================================================
// pipeline_pkg.sv - Lo que guarda cada registro de segmentacion
//
// Cada registro de segmentacion es UN pipe_reg del ancho exacto de su struct.
// El struct es la tabla de la seccion 2 de la guia escrita en HDL: si un campo
// no esta aqui, no viaja, y lo que no viaja se pierde.
//
// En riscv_segmentado.sv el contenido de cada registro se llama con la letra
// de la etapa que lo LEE:
//
//     D = IF/ID     E = ID/EX     M = EX/MEM     W = MEM/WB
//
// Asi, E.rd se lee "el rd de la que esta en EX" y es exactamente la senal que
// la guia llama rdE. M.reg_write es RegWriteM, W.rd es rdW, etc.
// =============================================================================
package pipeline_pkg;

    // -------------------------------------------------------------------------
    // Seleccion de los multiplexores de forwarding (ForwardAE / ForwardBE)
    // -------------------------------------------------------------------------
    localparam logic [1:0] FWD_RF  = 2'b00;   // del banco de registros
    localparam logic [1:0] FWD_WB  = 2'b01;   // de MEM/WB  (distancia 2)
    localparam logic [1:0] FWD_MEM = 2'b10;   // de EX/MEM  (distancia 1)

    // -------------------------------------------------------------------------
    // IF/ID - la instruccion, el PC y PC+4
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [31:0] instr;
        logic [31:0] pc;
        logic [31:0] pc_plus4;
    } if_id_t;

    // -------------------------------------------------------------------------
    // ID/EX - los dos valores leidos, PC, PC+4, inmediato, rs1, rs2, rd y las
    //         senales de control de EX, MEM y WB
    //
    // rs1 y rs2 viajan aunque sus valores ya se leyeron: la unidad de
    // forwarding compara NUMEROS de registro, y vive en EX.
    //
    // funct3 tambien viaja. No es una senal de la unidad de control, pero dos
    // etapas la necesitan despues de ID: EX (que condicion evalua el salto) y
    // MEM (de que ancho es el acceso: lb, lh, lw, sb, sh, sw).
    // -------------------------------------------------------------------------
    typedef struct packed {
        // --- control que se consume en EX ---
        logic        alu_src_a;     // 0 = rs1, 1 = PC (auipc)
        logic        alu_src_b;     // 0 = rs2, 1 = ImmExt
        logic [3:0]  alu_control;
        logic        branch;
        logic        jump;
        logic        jalr;
        logic [2:0]  funct3;
        // --- control que se consume en MEM ---
        logic        mem_write;
        // --- control que se consume en WB ---
        logic        reg_write;
        logic [1:0]  result_src;
        // --- datos ---
        logic [31:0] rd1;
        logic [31:0] rd2;
        logic [31:0] pc;
        logic [31:0] pc_plus4;
        logic [31:0] imm_ext;
        logic [4:0]  rs1;
        logic [4:0]  rs2;
        logic [4:0]  rd;
    } id_ex_t;

    // -------------------------------------------------------------------------
    // EX/MEM - el resultado, el dato a escribir en memoria, PC+4, el destino
    //          del salto, rd y las senales de MEM y WB
    //
    // alu_result NO es la salida cruda de la ALU: es la salida del multiplexor
    // de ResultSrc adelantado a EX (seccion 8). Lleva el valor DEFINITIVO de rd
    // para ALU, PC+4 y lui, y es lo que la unidad de forwarding adelanta desde
    // EX/MEM. En loads y stores es la direccion de memoria.
    // -------------------------------------------------------------------------
    typedef struct packed {
        // --- control que se consume en MEM ---
        logic        mem_write;
        logic [2:0]  funct3;
        // --- control que se consume en WB ---
        logic        reg_write;
        logic [1:0]  result_src;
        // --- datos ---
        logic [31:0] alu_result;
        logic [31:0] write_data;    // rs2 YA adelantado: lo que escribe un store
        logic [31:0] pc_plus4;
        logic [31:0] pc_target;     // el salto se resolvio en EX; queda como traza
        logic [4:0]  rd;
    } ex_mem_t;

    // -------------------------------------------------------------------------
    // MEM/WB - el dato leido de memoria, el resultado, PC+4, rd y las senales
    //          de WB
    // -------------------------------------------------------------------------
    typedef struct packed {
        // --- control que se consume en WB ---
        logic        reg_write;
        logic [1:0]  result_src;
        // --- datos ---
        logic [31:0] read_data;
        logic [31:0] alu_result;
        logic [31:0] pc_plus4;
        logic [4:0]  rd;
    } mem_wb_t;

endpackage
