class_name GrupoBarrera
extends Resource
## Un grupo de posiciones barrera del nivel. Las piezas se pueden colocar ahí y cuentan para las
## líneas, pero mientras la barrera esté activa sus casillas no generan sala. Un objetivo del
## nivel apaga el grupo por su nombre (Tetris.desactivar_barrera).

## Nombre del grupo: es lo que se usa para desactivarlo. Debe ser único en el nivel.
@export var nombre: StringName = &""

## Posiciones del tablero (x = columna, y = fila; 0 = fila de arriba).
@export var posiciones: Array[Vector2i] = []
