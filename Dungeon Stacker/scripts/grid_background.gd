extends Node2D
## Rejilla del tablero: el borde de cada casilla.

## Grosor de las líneas en píxeles de la pantalla del juego (1920x1080). Con 1 se pueden perder
## líneas cuando la ventana es más pequeña, porque se dibujan por debajo de un píxel real.
@export var grosor_linea := 2.0
@export var color_linea := Color(0.2, 0.2, 0.25)


func _draw():
	var Configuracion = Tetris.de(self).Configuracion
	for y in range(Configuracion.FILAS):
		for x in range(Configuracion.COLUMNAS):
			var posicion = Vector2(
				x * Configuracion.TAM_CELDA,
				y * Configuracion.TAM_CELDA
			)
			var rect = Rect2(
				posicion,
				Vector2(Configuracion.TAM_CELDA, Configuracion.TAM_CELDA)
				)
			draw_rect(rect, color_linea, false, grosor_linea)
