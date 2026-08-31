# Análisis de TP1_ALU y propuesta para Basys 3

## Resumen ejecutivo

El proyecto implementa una ALU combinacional de 8 bits con ocho operaciones y un módulo superior que permite cargar los operandos y el código de operación desde los switches de una placa. El resultado se muestra en ocho LED.

La lógica principal es coherente y la simulación guardada no muestra errores en los casos que alcanzó a ejecutar. Sin embargo, el registro de simulación está incompleto: el testbench necesita aproximadamente **5620 ns**, mientras que el script de XSim sólo ejecuta `run 1000ns`. Por eso el log termina en la cuarta resta y no verifica las ocho operaciones completas.

El proyecto selecciona el componente correcto, `xc7a35ticpg236-1L`, que corresponde al Artix-7 de la Basys 3 en versión industrial/low-voltage, pero **no tiene un archivo de restricciones XDC asociado**. Sin restricciones, Vivado puede simular el diseño pero no puede conectarlo correctamente con el reloj, switches, botones y LED de la placa.

## Archivos revisados

- `TP1_ALU/TP1_ALU.srcs/sources_1/new/tp1_alu.v`: ALU combinacional.
- `TP1_ALU/TP1_ALU.srcs/sources_1/new/top_module.v`: interfaz secuencial entre la ALU y la placa.
- `TP1_ALU/TP1_ALU.srcs/sim_1/new/test_bench.v`: banco de pruebas.
- `TP1_ALU/TP1_ALU.xpr`: configuración del proyecto Vivado.
- `TP1_ALU/TP1_ALU.sim/sim_1/behav/xsim/simulate.log`: resultado parcial de la simulación existente.
- `TP1_ALU/TP1_ALU.sim/sim_1/behav/xsim/test_bench.tcl`: duración configurada de la simulación.

## Arquitectura del diseño

El flujo de datos es:

```text
SW7..SW0 ──┬─ botón A  ──> A_reg[7:0] ──┐
           ├─ botón B  ──> B_reg[7:0] ──┼─> tp1_alu ─> LED7..LED0
           └─ botón OP ──> OP_reg[5:0] ─┘

BTN reset ──> borrado síncrono de A_reg, B_reg y OP_reg
CLK 100 MHz ─> registros del top_module
```

Se reutiliza el mismo banco de ocho switches. Primero se coloca el valor de `A` y se pulsa su botón; luego se hace lo mismo con `B`; finalmente se coloca el opcode en `SW5..SW0` y se pulsa el botón de operación. La salida cambia combinacionalmente cuando queda cargado el nuevo opcode.

## Análisis de `tp1_alu.v`

La ALU es combinacional porque utiliza `always @(*)`. La asignación inicial `result = 0` evita inferir un latch y define cero para cualquier opcode no reconocido.

| Operación | Opcode | Expresión | Comportamiento de 8 bits |
|---|---:|---|---|
| ADD | `100000` | `A_data + B_data` | Se descarta el carry; resultado módulo 256. |
| SUB | `100010` | `A_data - B_data` | Se descarta borrow; resultado en complemento a dos módulo 256. |
| AND | `100100` | `A_data & B_data` | AND bit a bit. |
| OR | `100101` | `A_data \| B_data` | OR bit a bit. |
| XOR | `100110` | `A_data ^ B_data` | XOR bit a bit. |
| SRA | `000011` | `$signed(A_data) >>> B_data` | Desplazamiento aritmético; replica el bit 7. |
| SRL | `000010` | `A_data >> B_data` | Desplazamiento lógico; completa con ceros. |
| NOR | `100111` | `~(A_data \| B_data)` | NOR bit a bit. |

### Aspectos correctos

- La lógica es puramente combinacional y tiene un valor por defecto.
- La conversión `$signed(A_data)` hace que `>>>` preserve el signo correctamente.
- El ancho de `result` fuerza de forma natural el comportamiento modular de suma y resta.
- Los parámetros permiten cambiar el ancho de datos, al menos para la mayoría de la estructura.

### Observaciones y posibles mejoras

1. Los opcodes se comparan contra literales fijos de 6 bits. Aunque existe `NB_OPCODE`, cambiarlo a un valor distinto de 6 rompería o volvería confuso el diseño. Conviene declarar `localparam [NB_OPCODE-1:0] OP_ADD = 6'b100000`, etc., o fijar explícitamente el opcode en 6 bits.
2. Un `case (OP_data)` sería más claro, fácil de mantener y apropiado para un decodificador de operaciones.
3. No existen salidas de estado como carry, overflow, cero o negativo. No es un error si no son parte de la consigna, pero el carry de suma y el overflow se pierden.
4. `B_data` completo se usa como cantidad de desplazamiento. Para datos de 8 bits, cualquier valor de `B >= 8` produce todo cero en SRL o todos los bits iguales al signo en SRA. Si la intención es permitir únicamente desplazamientos de 0 a 7, conviene usar `B_data[2:0]`.
5. Para opcodes inválidos la salida es cero. Es una decisión razonable, pero debería quedar documentada y probarse.

## Análisis de `top_module.v`

El módulo superior contiene tres registros:

- `A_reg[7:0]`: operando A.
- `B_reg[7:0]`: operando B.
- `OP_reg[5:0]`: operación.

En cada flanco ascendente del reloj:

- `reset=1` borra los tres registros.
- `buttons[0]=1` carga `switches` en A.
- `buttons[1]=1` carga `switches` en B.
- `buttons[2]=1` carga `switches[5:0]` en OP.

El reset tiene prioridad y es **síncrono**, por lo que sólo actúa en un flanco ascendente de `clk`. Si se mantienen dos o tres botones presionados a la vez, se cargan simultáneamente los registros correspondientes con el mismo valor de switches; esto es legal, aunque probablemente no sea el uso previsto.

### Riesgos al pasar del simulador a la placa

- Los pulsadores son señales asíncronas respecto del reloj de 100 MHz. El diseño no incluye sincronizadores, por lo que existe riesgo de metastabilidad.
- Los pulsadores mecánicos rebotan. En este caso el rebote normalmente recarga varias veces el mismo dato y puede no notarse, pero una interfaz robusta debería usar un sincronizador de dos flip-flops y detección de flanco/debounce.
- Mientras un botón esté pulsado, el registro se vuelve a cargar en cada ciclo. Funciona si los switches permanecen quietos, pero no genera un único pulso de carga.
- Los switches tampoco están sincronizados. La forma práctica de uso es fijar primero los switches y recién después pulsar el botón. Para máxima robustez también se pueden sincronizar.
- No se definió una restricción temporal para el reloj porque falta el XDC.

## Análisis del testbench

El testbench instancia el `top_module`, genera un reloj de 10 ns (100 MHz), aplica reset y ejecuta diez casos pseudoaleatorios para cada una de las ocho operaciones: **80 pruebas en total**.

Cada iteración carga A, B y OP mediante la misma secuencia que usaría una persona en la placa, calcula un valor esperado y compara `leds` con `===`. El uso de igualdad de cuatro estados es positivo porque detectaría valores `X` o `Z`.

### Resultado de la simulación existente

El log contiene:

- 10 casos ADD correctos.
- 4 casos SUB correctos.
- 0 mensajes `ERROR` antes del corte.

Esto no significa que el testbench completo haya pasado. Cada caso consume 70 ns, el reset inicial consume 20 ns y las 80 pruebas requieren aproximadamente:

```text
20 ns + (80 × 70 ns) = 5620 ns
```

El archivo `test_bench.tcl` contiene `run 1000ns`, que explica exactamente el corte después de 14 casos. Debe cambiarse a, por ejemplo, `run 6us`, o utilizarse `run all`, para que `$finish` termine la simulación.

### Debilidades de cobertura

1. El testbench sólo imprime errores; no mantiene un contador ni termina con `$fatal`. Una ejecución automatizada podría devolver éxito aunque hubiese fallos funcionales.
2. No comprueba explícitamente que el reset haya dejado A, B, OP y LED en cero.
3. No prueba reset durante una operación ni la prioridad de reset sobre los botones.
4. No prueba opcodes inválidos y, por lo tanto, no confirma el cero por defecto.
5. En los shifts, `B_data` es aleatorio entre 0 y 255. Sólo 8 de 256 valores representan desplazamientos interesantes de 0 a 7; aproximadamente el 96,9 % de los casos tenderán a producir una salida totalmente rellenada. Conviene dirigir pruebas a `B = 0, 1, 7, 8` y algunos valores mayores.
6. Los resultados esperados repiten casi literalmente las expresiones del DUT. Esto comprueba integración, pero puede repetir el mismo error conceptual.
7. No hay casos dirigidos para overflow/underflow: por ejemplo `8'hFF + 1`, `0 - 1`, números negativos en SRA, cero y patrones alternados.
8. `$random` no tiene una semilla documentada, lo cual dificulta reproducir de manera explícita una secuencia entre simuladores.
9. La secuencia se repite muchas veces. Una `task` para cargar A/B/OP y otra para comprobar resultados reducirían mucho el archivo y los errores de mantenimiento.

Una mejora mínima sería añadir contadores `passes`/`errors`, casos dirigidos, `run all` y al final:

```verilog
if (errors != 0)
  $fatal(1, "Fallaron %0d casos", errors);
else
  $display("PASS: todas las pruebas correctas");
```

## Asociación recomendada con la Basys 3

Se propone una interfaz simple y fácil de recordar:

| Señal Verilog | Elemento Basys 3 | Uso | Pin FPGA |
|---|---|---|---|
| `clk` | Oscilador de 100 MHz | Reloj del sistema | W5 |
| `reset` | BTNC | Borrar A, B y OP | U18 |
| `buttons[0]` | BTNL | Cargar A | W19 |
| `buttons[1]` | BTNR | Cargar B | T17 |
| `buttons[2]` | BTNU | Cargar opcode | T18 |
| `switches[0]` ... `[7]` | SW0 ... SW7 | Dato u opcode | V17, V16, W16, W17, W15, V15, W14, W13 |
| `leds[0]` ... `[7]` | LD0 ... LD7 | Resultado | U16, E19, U19, V19, W18, U15, U14, V14 |

Los LED de la Basys 3 son activos en alto, por lo que no hace falta invertir `leds`: un `1` lógico enciende el LED correspondiente.

### XDC sugerido

Crear, por ejemplo, `TP1_ALU/TP1_ALU.srcs/constrs_1/new/basys3.xdc`, agregarlo al conjunto `constrs_1` y usar:

```tcl
## Reloj de 100 MHz
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0.000 5.000} [get_ports clk]

## Reset: botón central
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports reset]

## Botones: izquierda=A, derecha=B, arriba=OP
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports {buttons[0]}]
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports {buttons[1]}]
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports {buttons[2]}]

## Switches SW0..SW7
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {switches[0]}]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports {switches[1]}]
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS33 } [get_ports {switches[2]}]
set_property -dict { PACKAGE_PIN W17 IOSTANDARD LVCMOS33 } [get_ports {switches[3]}]
set_property -dict { PACKAGE_PIN W15 IOSTANDARD LVCMOS33 } [get_ports {switches[4]}]
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports {switches[5]}]
set_property -dict { PACKAGE_PIN W14 IOSTANDARD LVCMOS33 } [get_ports {switches[6]}]
set_property -dict { PACKAGE_PIN W13 IOSTANDARD LVCMOS33 } [get_ports {switches[7]}]

## LED LD0..LD7
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {leds[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {leds[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {leds[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {leds[3]}]
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {leds[4]}]
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {leds[5]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {leds[6]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {leds[7]}]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
```

Los nombres dentro de `get_ports` coinciden exactamente con los puertos actuales de `top_module`, por lo que no hace falta renombrar el HDL.

## Procedimiento de uso en la placa

1. Pulsar BTNC para iniciar A, B y OP en cero.
2. Colocar A en SW7..SW0 y pulsar BTNL.
3. Colocar B en SW7..SW0 y pulsar BTNR.
4. Colocar el opcode en SW5..SW0 y pulsar BTNU. SW7 y SW6 no participan en el opcode.
5. Leer el resultado binario en LD7..LD0.

Ejemplo: para calcular `5 + 3`, cargar `00000101` con BTNL, cargar `00000011` con BTNR y luego colocar `00100000` (los seis bits bajos son `100000`) y pulsar BTNU. Los LED deberían mostrar `00001000`.

## Prioridades recomendadas

1. Añadir el archivo XDC y ejecutar síntesis, implementación y generación de bitstream.
2. Cambiar la simulación a `run all` o al menos `run 6us`.
3. Convertir el testbench en autochecking con contador de errores y `$fatal`.
4. Añadir casos dirigidos, especialmente para shifts, reset, overflow modular y opcodes inválidos.
5. Para una entrega robusta en hardware, sincronizar y aplicar debounce/detección de flanco a los botones.

## Fuentes de la asignación física

- [Archivo XDC maestro oficial de Digilent para Basys 3](https://github.com/Digilent/digilent-xdc/blob/master/Basys-3-Master.xdc)
- [Manual de referencia oficial de Basys 3](https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys3_rm.pdf)

Los pines y el estándar `LVCMOS33` de la propuesta fueron tomados de esas fuentes oficiales y adaptados a los nombres de los puertos de este proyecto.
