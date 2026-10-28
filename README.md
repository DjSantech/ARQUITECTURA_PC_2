# Arquitectura de Computadores · UTP

Talleres de RV32I de Santiago Guevara Méndez.

## Taller 1 · Búsqueda binaria en RV32I

Traducción a ensamblador RV32I de una búsqueda binaria recursiva en C (`main`, la función recursiva y dos funciones auxiliares).

| Archivo | Qué es |
|---|---|
| `busqueda_binaria.s` | el programa completo, solo con instrucciones base |
| `Taller1_Busqueda_Binaria_RV32I.docx` | el informe: registros, frames, seguimiento a mano, pila de `x = 4` y codificación de tres instrucciones |

Resultados: `x = 23 → 5`, `2 → 0`, `91 → 9`, `4 → −1`, `100 → −1`.

## Taller 2 · Procesador monociclo RV32I

Carpeta [`taller-procesador/`](taller-procesador). Los archivos escritos son `adder.sv`, `mux2.sv`, `mux4.sv`, `imm_gen.sv`, `data_memory.sv`, `control_unit.sv` y `riscv_monociclo.sv`, en `rtl/`. El resto es el material inicial del curso, sin cambios.

Los cinco testbenches pasan: 86 de 86 comprobaciones.

| Testbench | Comprobaciones |
|---|---|
| `tb_basicos` | 12 |
| `tb_imm_gen` | 10 |
| `tb_data_memory` | 16 |
| `tb_control_unit` | 18 |
| `tb_cpu` | 30 |

### Correr las pruebas

Con Icarus Verilog: `make` dentro de `taller-procesador`.

Con ModelSim (Intel FPGA Starter Edition), desde `taller-procesador`:

```powershell
vsim -c -do sim/correr_pruebas.do     # los cinco testbenches
```

Dentro de ModelSim, `do sim/ondas_cpu.do` abre las ondas del procesador ejecutando `completo.s`.

### Quartus

`taller-procesador/quartus/taller2.qpf` (Cyclone V 5CSEMA5F31C6, DE1-SoC). Analysis & Elaboration termina sin errores.
