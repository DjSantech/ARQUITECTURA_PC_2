# =============================================================================
# correr_pruebas.do - Los cinco testbenches en ModelSim / Questa (sin make)
#
# Equivale a "make all". Se corre desde la carpeta taller-procesador:
#
#   consola:   vsim -c -do sim/correr_pruebas.do
#   ModelSim:  File > Change Directory... (taller-procesador)  y luego
#              en la ventana Transcript:   do sim/correr_pruebas.do
#
# -suppress 7061: register_file.sv (material del profesor) escribe regs en un
# initial y en un always_ff. iverilog lo acepta; ModelSim lo marca como error
# suprimible. No es un fallo del diseno.
# =============================================================================

# 1. Ensamblar los programas (prog/*.s -> prog/*.hex)
foreach p {humo completo bytes} {
    exec python tools/rvasm.py prog/$p.s -o prog/$p.hex
}

# 2. Compilar todo en build/work
file mkdir build
if {[file exists build/work]} { vdel -lib build/work -all }
vlib build/work
vmap work build/work

vlog -sv -suppress 7061 -work work \
    rtl/riscv_pkg.sv rtl/pc.sv rtl/alu.sv rtl/register_file.sv \
    rtl/instruction_memory.sv rtl/adder.sv rtl/mux2.sv rtl/mux4.sv \
    rtl/imm_gen.sv rtl/data_memory.sv rtl/control_unit.sv \
    rtl/riscv_monociclo.sv \
    tb/tb_basicos.sv tb/tb_imm_gen.sv tb/tb_data_memory.sv \
    tb/tb_control_unit.sv tb/tb_cpu.sv

# 3. Correr los cinco, en el orden del Makefile
foreach tb {tb_basicos tb_imm_gen tb_data_memory tb_control_unit tb_cpu} {
    echo ""
    echo "=== $tb ==="
    vsim -onfinish stop -quiet work.$tb
    run -all
    quit -sim
}

if {[batch_mode]} { quit -f }
