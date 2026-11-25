# =============================================================================
# correr_pruebas.do - Los cuatro testbenches del Taller 3 en ModelSim / Questa
#
# Se corre desde la carpeta taller-segmentacion:
#
#   consola:   vsim -c -do sim/correr_pruebas.do
#   ModelSim:  File > Change Directory... (taller-segmentacion)  y luego
#              en la ventana Transcript:   do sim/correr_pruebas.do
#
# Los modulos del Taller 2 NO se copian: se compilan desde
# ../taller-procesador/rtl, tal cual. Es la prueba de que segmentar no cambio
# ninguno de ellos. El monociclo tambien se compila, porque tb_segmentado lo
# usa como referencia instruccion a instruccion.
#
# -suppress 7061: register_file.sv (material del curso) escribe regs en un
# initial y en un always_ff. No es un fallo del diseno.
# =============================================================================

set T2 ../taller-procesador

# 1. Ensamblar los programas (prog/*.s -> prog/*.hex) con el ensamblador del curso
foreach s [glob prog/*.s] {
    set h [file rootname $s].hex
    exec python $T2/tools/rvasm.py $s -o $h
}

# 2. Compilar todo en build/work
file mkdir build
if {[file exists build/work]} { vdel -lib build/work -all }
vlib build/work
vmap work build/work

vlog -sv -suppress 7061 -work work \
    $T2/rtl/riscv_pkg.sv $T2/rtl/pc.sv $T2/rtl/alu.sv $T2/rtl/register_file.sv \
    $T2/rtl/instruction_memory.sv $T2/rtl/adder.sv $T2/rtl/mux2.sv $T2/rtl/mux4.sv \
    $T2/rtl/imm_gen.sv $T2/rtl/data_memory.sv $T2/rtl/control_unit.sv \
    $T2/rtl/riscv_monociclo.sv \
    rtl/pipeline_pkg.sv rtl/pipe_reg.sv rtl/forwarding_unit.sv rtl/hazard_unit.sv \
    rtl/riscv_segmentado.sv \
    tb/tb_pipe_reg.sv tb/tb_forwarding_unit.sv tb/tb_hazard_unit.sv tb/tb_segmentado.sv \
    tb/tb_traza.sv

# 3. Correr los cuatro, en el orden de las fases de la guia
foreach tb {tb_pipe_reg tb_forwarding_unit tb_hazard_unit tb_segmentado} {
    echo ""
    echo "=== $tb ==="
    vsim -onfinish stop -quiet work.$tb
    run -all
    quit -sim
}

if {[batch_mode]} { quit -f }
