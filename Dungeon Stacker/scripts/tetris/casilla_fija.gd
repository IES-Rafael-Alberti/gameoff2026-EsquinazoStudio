class_name CasillaFija
extends Resource
## Una habitación fija del nivel: está en una coordenada del tablero desde el principio, no se
## mueve ni se borra al hacer línea, pero cuenta para completarla. Genera sala y puertas.

## Posición en el tablero: x = columna, y = fila (0 = fila de arriba).
@export var posicion := Vector2i.ZERO

## Escena de la sala que se carga en esa casilla.
@export var escena: PackedScene
