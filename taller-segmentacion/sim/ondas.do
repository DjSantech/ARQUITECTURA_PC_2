# =============================================================================
# ondas.do - El procesador segmentado en la ventana de ondas de ModelSim
#
# Correr DESPUES de sim/correr_pruebas.do (que deja compilado build/work),
# desde la carpeta taller-segmentacion, en la ventana Transcript:
#
#     do sim/ondas.do
#
# Carga prog/acumulador.hex: un bucle con un lw seguido de su uso, asi que en
# las ondas se ven las tres cosas del taller:
#   - StallF / StallD / FlushE subiendo juntas en cada vuelta (load-use)
#   - FlushD / FlushE subiendo juntas en cada bne tomado
#   - ForwardAE / ForwardBE eligiendo 01 (MEM/WB) despues de cada parada
# =============================================================================
vmap work build/work
vsim -onfinish stop -G INIT_FILE=prog/acumulador.hex -G CICLOS=45 work.tb_traza

set P /tb_traza/dut

add wave -divider "reloj"
add wave /tb_traza/clk
add wave -divider "IF"
add wave -radix hex $P/PCF $P/InstrF
add wave -divider "ID"
add wave -radix hex $P/D.pc $P/D.instr
add wave -radix unsigned $P/rs1D $P/rs2D
add wave -divider "EX"
add wave -radix hex $P/E.pc
add wave -radix unsigned $P/E.rs1 $P/E.rs2 $P/E.rd $P/E.result_src
add wave $P/ForwardAE $P/ForwardBE
add wave -radix decimal $P/SrcAE $P/SrcBE $P/ResultE
add wave $P/PCSrcE
add wave -divider "MEM"
add wave -radix unsigned $P/M.rd
add wave $P/M.reg_write
add wave -radix decimal $P/M.alu_result $P/ReadDataM
add wave -divider "WB"
add wave -radix unsigned $P/W.rd
add wave $P/W.reg_write
add wave -radix decimal $P/ResultW
add wave -divider "unidad de riesgos"
add wave -color yellow $P/StallF $P/StallD $P/FlushD $P/FlushE
add wave -divider "registros"
add wave -radix decimal -label "x5 (dato)"       $P/rf/regs(5)
add wave -radix decimal -label "x6 (acumulador)" $P/rf/regs(6)
add wave -radix decimal -label "x7 (vueltas)"    $P/rf/regs(7)
add wave -radix decimal -label "x11 (contador)"  $P/rf/regs(11)

run -all
wave zoom full
