class_name PiezaConPeso
extends Resource
## Una pieza escogida que entra en el sorteo de cada pieza con un peso relativo.

@export_range(0.0, 100.0, 0.1) var peso := 1.0
@export var pieza: PiezaEscogida
