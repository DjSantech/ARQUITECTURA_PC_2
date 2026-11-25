// =============================================================================
// riscv_segmentado.sv - El procesador RV32I segmentado en cinco etapas
//
// Es el riscv_monociclo.sv del Taller 2 cortado en cinco etapas, con dos
// unidades nuevas. Todos los modulos de calculo son los del Taller 2 SIN UN
// CAMBIO (se compilan desde ../taller-procesador/rtl): pc, adder,
// instruction_memory, control_unit, register_file, imm_gen, mux2, mux4, alu,
// data_memory. Lo nuevo es solo:
//
//   - cuatro registros de segmentacion (pipe_reg, contenido en pipeline_pkg)
//   - forwarding_unit en EX y sus dos multiplexores de tres entradas
//   - hazard_unit en ID y sus tres/cuatro senales de parada y borrado
//   - los cables que los unen
//
// CONVENCION DE NOMBRES. Cada senal lleva al final la letra de la etapa en la
// que esta: F, D, E, M, W. El contenido de cada registro de segmentacion se
// llama con la letra de la etapa que lo lee:
//
//     D = IF/ID     E = ID/EX     M = EX/MEM     W = MEM/WB
//
// asi que E.rd es rdE ("el rd de la que esta en EX"), M.reg_write es
// RegWriteM y W.rd es rdW.
//
// Las instancias rf y dmem conservan su nombre: el testbench lee
// dut.rf.regs[i] y dut.dmem.mem[i], igual que en el Taller 2.
// =============================================================================
module riscv_segmentado #(
    parameter int IMEM_DEPTH = 256,
    parameter int DMEM_DEPTH = 256,
    parameter     INIT_FILE  = ""
)(
    input logic clk,
    input logic rst,
    input logic en
);

    import riscv_pkg::*;
    import pipeline_pkg::*;

    // =========================================================================
    // Los cuatro registros de segmentacion: lo que entra (_d) y lo que guardan
    // =========================================================================
    if_id_t  if_id_d,  D;
    id_ex_t  id_ex_d,  E;
    ex_mem_t ex_mem_d, M;
    mem_wb_t mem_wb_d, W;

    // =========================================================================
    // Senales de las dos unidades
    // =========================================================================
    logic       StallF, StallD, FlushD, FlushE;   // unidad de riesgos
    logic [1:0] ForwardAE, ForwardBE;             // unidad de forwarding

    // Dos senales que vuelven de EX hacia IF: el salto se decide en EX
    logic        PCSrcE;
    logic [31:0] PCTargetE;

    // Lo que se escribe en rd: vuelve de WB hacia ID (banco) y hacia EX
    logic [31:0] ResultW;


    // #########################################################################
    // IF - busqueda
    // #########################################################################
    logic [31:0] PCF, PCNextF, PCPlus4F, InstrF;

    // El PC se congela con StallF: se vuelve a buscar la misma instruccion
    pc registro_pc (
        .clk     (clk),
        .rst     (rst),
        .en      (en & ~StallF),
        .pc_next (PCNextF),
        .pc      (PCF)
    );

    adder add_pc4 (
        .a (PCF),
        .b (32'd4),
        .y (PCPlus4F)
    );

    instruction_memory #(
        .DEPTH     (IMEM_DEPTH),
        .INIT_FILE (INIT_FILE)
    ) imem (
        .addr  (PCF),
        .instr (InstrF)
    );

    // El proximo PC: secuencial, o el destino que decidio EX
    mux2 #(.W (32)) mux_pc (
        .d0  (PCPlus4F),
        .d1  (PCTargetE),
        .sel (PCSrcE),
        .y   (PCNextF)
    );

    // ---- IF/ID: la instruccion, el PC y PC+4 --------------------------------
    assign if_id_d.instr    = InstrF;
    assign if_id_d.pc       = PCF;
    assign if_id_d.pc_plus4 = PCPlus4F;

    pipe_reg #(.W ($bits(if_id_t))) reg_if_id (
        .clk (clk),
        .rst (rst),
        .en  (en & ~StallD),      // StallD: la dependiente se queda en ID
        .clr (en & FlushD),       // FlushD: muere la que venia en IF
        .d   (if_id_d),
        .q   (D)
    );


    // #########################################################################
    // ID - decodificacion y lectura del banco
    // #########################################################################
    logic [6:0]  opcodeD;
    logic [2:0]  funct3D;
    logic        funct7b5D;
    logic [4:0]  rs1D, rs2D, rdD;
    logic [31:0] RD1D, RD2D, ImmExtD;

    // Los campos de la instruccion: cortes, no logica
    assign opcodeD   = D.instr[6:0];
    assign funct3D   = D.instr[14:12];
    assign funct7b5D = D.instr[30];
    assign rs1D      = D.instr[19:15];
    assign rs2D      = D.instr[24:20];
    assign rdD       = D.instr[11:7];

    // Las senales de control se generan todas aqui y viajan con la instruccion
    logic       RegWriteD, ALUSrcAD, ALUSrcBD, MemWriteD;
    logic       BranchD, JumpD, JalrD;
    logic [2:0] ImmSrcD;
    logic [1:0] ResultSrcD;
    logic [3:0] ALUControlD;

    // La misma unidad de control del Taller 2. Sus banderas de entrada y su
    // salida pc_src quedan sin uso: las banderas de la ALU existen recien en
    // EX, y ahi se toma la decision del salto (bloque "PCSrcE", mas abajo).
    control_unit control (
        .opcode      (opcodeD),
        .funct3      (funct3D),
        .funct7b5    (funct7b5D),
        .zero        (1'b0),
        .less        (1'b0),
        .less_u      (1'b0),
        .reg_write   (RegWriteD),
        .imm_src     (ImmSrcD),
        .alu_src_a   (ALUSrcAD),
        .alu_src_b   (ALUSrcBD),
        .mem_write   (MemWriteD),
        .result_src  (ResultSrcD),
        .branch      (BranchD),
        .jump        (JumpD),
        .jalr        (JalrD),
        .alu_control (ALUControlD),
        .pc_src      ()
    );

    // El banco se lee en ID y se escribe desde WB.
    //
    // Recibe el reloj INVERTIDO. register_file.sv escribe en el flanco de
    // subida de su clk; con ~clk ese flanco cae a MITAD del ciclo. Asi el
    // banco escribe en la primera mitad y la lectura combinacional de ID ve
    // el valor nuevo en la segunda, antes de que ID/EX lo capture. Es lo que
    // resuelve la distancia 3 (WB escribe x5 en el mismo ciclo en que ID lo
    // lee) sin un multiplexor mas y sin tocar el modulo del Taller 2.
    // Con .clk(clk) toda dependencia a distancia 3 lee el valor viejo.
    register_file rf (
        .clk (~clk),
        .we  (W.reg_write),
        .rs1 (rs1D),
        .rs2 (rs2D),
        .rd  (W.rd),
        .wd3 (ResultW),
        .rd1 (RD1D),
        .rd2 (RD2D)
    );

    imm_gen ig (
        .instr   (D.instr),
        .imm_src (ImmSrcD),
        .imm_ext (ImmExtD)
    );

    // La unidad de deteccion de riesgos mira IF/ID y ID/EX
    hazard_unit hu (
        .rs1D       (rs1D),
        .rs2D       (rs2D),
        .rdE        (E.rd),
        .ResultSrcE (E.result_src),
        .PCSrcE     (PCSrcE),
        .StallF     (StallF),
        .StallD     (StallD),
        .FlushD     (FlushD),
        .FlushE     (FlushE)
    );

    // ---- ID/EX ---------------------------------------------------------------
    assign id_ex_d.alu_src_a   = ALUSrcAD;
    assign id_ex_d.alu_src_b   = ALUSrcBD;
    assign id_ex_d.alu_control = ALUControlD;
    assign id_ex_d.branch      = BranchD;
    assign id_ex_d.jump        = JumpD;
    assign id_ex_d.jalr        = JalrD;
    assign id_ex_d.funct3      = funct3D;
    assign id_ex_d.mem_write   = MemWriteD;
    assign id_ex_d.reg_write   = RegWriteD;
    assign id_ex_d.result_src  = ResultSrcD;
    assign id_ex_d.rd1         = RD1D;
    assign id_ex_d.rd2         = RD2D;
    assign id_ex_d.pc          = D.pc;
    assign id_ex_d.pc_plus4    = D.pc_plus4;
    assign id_ex_d.imm_ext     = ImmExtD;
    assign id_ex_d.rs1         = rs1D;
    assign id_ex_d.rs2         = rs2D;
    assign id_ex_d.rd          = rdD;

    pipe_reg #(.W ($bits(id_ex_t))) reg_id_ex (
        .clk (clk),
        .rst (rst),
        .en  (en),
        .clr (en & FlushE),       // FlushE: burbuja (load-use) o matar (salto)
        .d   (id_ex_d),
        .q   (E)
    );


    // #########################################################################
    // EX - ejecucion
    // #########################################################################
    logic [31:0] FwdAE;          // rs1 con el valor bueno
    logic [31:0] WriteDataE;     // rs2 con el valor bueno (tambien el dato del sw)
    logic [31:0] SrcAE, SrcBE;
    logic [31:0] ALUResultE;
    logic        ZeroE, LessE, LessUE;
    logic [31:0] PCPlusImmE, JalrTargetE;
    logic [31:0] ResultE;        // valor definitivo de rd que se lleva a EX/MEM

    forwarding_unit fu (
        .rs1E      (E.rs1),
        .rs2E      (E.rs2),
        .rdM       (M.rd),
        .rdW       (W.rd),
        .RegWriteM (M.reg_write),
        .RegWriteW (W.reg_write),
        .ForwardAE (ForwardAE),
        .ForwardBE (ForwardBE)
    );

    // Los dos multiplexores de tres entradas: el mux4 del Taller 2 con la
    // entrada 11 sin usar (la unidad de forwarding nunca la elige).
    //   00 = banco    01 = MEM/WB (ResultW)    10 = EX/MEM (ALUResultM)
    mux4 #(.W (32)) mux_fwd_a (
        .d00 (E.rd1),
        .d01 (ResultW),
        .d10 (M.alu_result),
        .d11 (32'd0),
        .sel (ForwardAE),
        .y   (FwdAE)
    );

    mux4 #(.W (32)) mux_fwd_b (
        .d00 (E.rd2),
        .d01 (ResultW),
        .d10 (M.alu_result),
        .d11 (32'd0),
        .sel (ForwardBE),
        .y   (WriteDataE)
    );

    // Despues del forwarding, los dos multiplexores de operando del Taller 2
    mux2 #(.W (32)) mux_a (
        .d0  (FwdAE),
        .d1  (E.pc),               // auipc: el PC de ESTA instruccion
        .sel (E.alu_src_a),
        .y   (SrcAE)
    );

    mux2 #(.W (32)) mux_b (
        .d0  (WriteDataE),
        .d1  (E.imm_ext),
        .sel (E.alu_src_b),
        .y   (SrcBE)
    );

    alu alu_i (
        .src_a       (SrcAE),
        .src_b       (SrcBE),
        .alu_control (E.alu_control),
        .alu_result  (ALUResultE),
        .zero        (ZeroE),
        .less        (LessE),
        .less_u      (LessUE)
    );

    // Destino del salto: PC + ImmExt con el PC de esta instruccion, o el de
    // jalr (rs1 + imm con el bit 0 a cero)
    adder add_tgt (
        .a (E.pc),
        .b (E.imm_ext),
        .y (PCPlusImmE)
    );

    assign JalrTargetE = {ALUResultE[31:1], 1'b0};

    mux2 #(.W (32)) mux_jalr (
        .d0  (PCPlusImmE),
        .d1  (JalrTargetE),
        .sel (E.jalr),
        .y   (PCTargetE)
    );

    // ---- PCSrcE: el bloque 3 de la unidad de control, en la etapa donde
    //      existen las banderas. Las mismas seis condiciones del Taller 2. ----
    logic BranchTakenE;

    always_comb begin
        BranchTakenE = 1'b0;
        if (E.branch) begin
            case (E.funct3)
                F3_BEQ:  BranchTakenE =  ZeroE;
                F3_BNE:  BranchTakenE = ~ZeroE;
                F3_BLT:  BranchTakenE =  LessE;
                F3_BGE:  BranchTakenE = ~LessE;
                F3_BLTU: BranchTakenE =  LessUE;
                F3_BGEU: BranchTakenE = ~LessUE;
                default: BranchTakenE = 1'b0;
            endcase
        end
    end

    assign PCSrcE = BranchTakenE | E.jump;

    // ---- El multiplexor de ResultSrc, adelantado a EX (seccion 8) -----------
    // Tres de los cuatro valores que puede escribir rd ya existen aqui. Con
    // esto EX/MEM lleva el valor definitivo de rd, y el forwarding adelanta
    // lo correcto tambien para lui (11) y jal/jalr (10). El caso 01 (load)
    // deja pasar la direccion: el dato aun no existe, y por eso el load es
    // el unico caso que obliga a parar.
    mux4 #(.W (32)) mux_res_ex (
        .d00 (ALUResultE),
        .d01 (ALUResultE),         // load: la direccion (el dato llega en MEM)
        .d10 (E.pc_plus4),         // jal, jalr
        .d11 (E.imm_ext),          // lui
        .sel (E.result_src),
        .y   (ResultE)
    );

    // ---- EX/MEM --------------------------------------------------------------
    assign ex_mem_d.mem_write  = E.mem_write;
    assign ex_mem_d.funct3     = E.funct3;
    assign ex_mem_d.reg_write  = E.reg_write;
    assign ex_mem_d.result_src = E.result_src;
    assign ex_mem_d.alu_result = ResultE;
    assign ex_mem_d.write_data = WriteDataE;
    assign ex_mem_d.pc_plus4   = E.pc_plus4;
    assign ex_mem_d.pc_target  = PCTargetE;
    assign ex_mem_d.rd         = E.rd;

    pipe_reg #(.W ($bits(ex_mem_t))) reg_ex_mem (
        .clk (clk),
        .rst (rst),
        .en  (en),
        .clr (1'b0),
        .d   (ex_mem_d),
        .q   (M)
    );


    // #########################################################################
    // MEM - memoria de datos
    // #########################################################################
    logic [31:0] ReadDataM;

    data_memory #(
        .DEPTH (DMEM_DEPTH)
    ) dmem (
        .clk    (clk),
        .we     (M.mem_write),
        .funct3 (M.funct3),
        .addr   (M.alu_result),
        .wd     (M.write_data),
        .rd     (ReadDataM)
    );

    // ---- MEM/WB --------------------------------------------------------------
    assign mem_wb_d.reg_write  = M.reg_write;
    assign mem_wb_d.result_src = M.result_src;
    assign mem_wb_d.read_data  = ReadDataM;
    assign mem_wb_d.alu_result = M.alu_result;
    assign mem_wb_d.pc_plus4   = M.pc_plus4;
    assign mem_wb_d.rd         = M.rd;

    pipe_reg #(.W ($bits(mem_wb_t))) reg_mem_wb (
        .clk (clk),
        .rst (rst),
        .en  (en),
        .clr (1'b0),
        .d   (mem_wb_d),
        .q   (W)
    );


    // #########################################################################
    // WB - escritura
    // #########################################################################
    // El multiplexor de ResultSrc del Taller 2. Con el de EX puesto, 00 y 11
    // ya llegan resueltos en alu_result; 01 es el dato de memoria y 10 PC+4.
    mux4 #(.W (32)) mux_res (
        .d00 (W.alu_result),
        .d01 (W.read_data),
        .d10 (W.pc_plus4),
        .d11 (W.alu_result),       // lui: el inmediato ya viene en alu_result
        .sel (W.result_src),
        .y   (ResultW)
    );

endmodule
