# =============================================================================
# ondas_cpu.do - Abre tb_cpu en ModelSim con las senales del programa completo
#
# Correr DESPUES de sim/correr_pruebas.do (que deja compilado build/work),
# desde la carpeta taller-procesador, en la ventana Transcript de ModelSim:
#
#     do sim/ondas_cpu.do
#
# Cada flanco de subida de clk es una instruccion: mira pc_actual e instr y
# sigue como cambian las senales de control y el resultado.
# =============================================================================
vmap work build/work
vsim -onfinish stop work.tb_cpu

set P /tb_cpu/cpu_completo
add wave -divider "reloj y reset"
add wave /tb_cpu/clk /tb_cpu/rst
add wave -divider "instruccion"
add wave -radix hex $P/pc_actual $P/instr
add wave -radix unsigned $P/opcode $P/funct3 $P/rs1 $P/rs2 $P/rd
add wave -divider "control"
add wave $P/reg_write $P/imm_src $P/alu_src_a $P/alu_src_b $P/mem_write
add wave $P/result_src $P/branch $P/jump $P/jalr $P/alu_control $P/pc_src
add wave -divider "datos"
add wave -radix decimal $P/rd1 $P/rd2 $P/imm_ext $P/alu_result
add wave $P/zero $P/less $P/less_u
add wave -radix decimal $P/read_data $P/result
add wave -radix hex $P/pc_plus4 $P/pc_target $P/pc_next
add wave -divider "registros x1..x15"
for {set i 1} {$i <= 15} {incr i} {
    add wave -radix decimal -label "x$i" $P/rf/regs($i)
}

run 300 ns
wave zoom full
