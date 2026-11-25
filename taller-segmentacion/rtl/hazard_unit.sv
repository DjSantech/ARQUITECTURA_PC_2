// =============================================================================
// hazard_unit.sv - Unidad de deteccion de riesgos (vive en ID)
//
// Hace dos trabajos con las mismas cuatro salidas:
//
// 1. LOAD-USE. Un load en EX y, en ID, una instruccion que lee el registro
//    que ese load va a escribir (por rs1 o por rs2). El dato sale de memoria
//    al final de MEM y la ALU lo necesitaria al principio de ese mismo ciclo:
//    ningun cable lo arregla. Se para el frente un ciclo y se mete una
//    burbuja; despues el lw queda a distancia 2 y el camino 01 de la unidad
//    de forwarding lo cubre.
//
//      StallF  = 1   el PC no avanza: se vuelve a buscar la misma instruccion
//      StallD  = 1   IF/ID se queda igual: la dependiente sigue en ID
//      FlushE  = 1   ID/EX a cero: entra un nop en EX
//
//    Las tres van JUNTAS. Parar sin vaciar ID/EX ejecuta la instruccion dos
//    veces; vaciar sin parar la pierde.
//
// 2. SALTO TOMADO. El salto se decide en EX (PCSrcE = 1); para entonces las
//    dos instrucciones de detras ya estan en IF e ID y hay que matarlas:
//
//      FlushD  = 1   IF/ID a cero: muere la que venia en IF
//      FlushE  = 1   ID/EX a cero: muere la que estaba en ID
//
// Las dos causas no coinciden nunca: una exige un load en EX y la otra un
// salto en EX.
//
// "Es un load" se reconoce con los DOS bits de ResultSrcE contra 01. Harris &
// Harris miran solo el bit 0 porque en su diseno ResultSrc nunca vale 11; en
// este curso 11 es lui, y con un solo bit cada lui seguido de un uso de su rd
// pararia un ciclo sin necesidad.
//
// Vive en ID porque cuando la dependiente llega a EX ya es tarde: hay que
// detenerla antes. Por eso sus entradas llevan sufijos D y E.
// Combinacional pura, sin reloj y sin estado.
// =============================================================================
module hazard_unit (
    input  logic [4:0] rs1D,        // registros que lee la que esta en ID
    input  logic [4:0] rs2D,
    input  logic [4:0] rdE,         // destino de la que esta en EX
    input  logic [1:0] ResultSrcE,  // 01 = la de EX es un load
    input  logic       PCSrcE,      // 1 = la de EX es un salto tomado
    output logic       StallF,
    output logic       StallD,
    output logic       FlushD,
    output logic       FlushE
);

    import riscv_pkg::*;

    logic lwStall;

    assign lwStall = (ResultSrcE == RES_MEM) && ((rs1D == rdE) || (rs2D == rdE));

    assign StallF = lwStall;
    assign StallD = lwStall;
    assign FlushD = PCSrcE;
    assign FlushE = lwStall | PCSrcE;

endmodule
