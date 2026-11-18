class_name PiezaEnTurno
extends Resource
## Una pieza escogida que sale en un turno concreto del nivel.

## Número de pieza del nivel en la que sale: 1 = la primera pieza, 2 = la segunda...
@export_range(1, 999, 1, "or_greater") var turno := 1
@export var pieza: PiezaEscogida
