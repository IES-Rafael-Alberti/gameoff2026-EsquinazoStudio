extends Node2D
const Configuracion = preload("res://scripts/configuracion.gd")

func _draw():
	for y in range(	Configuracion.FILAS):
		for x in range(	Configuracion.COLUMNAS):
			var posicion = Vector2(
				x * 	Configuracion.TAM_CELDA,
				y * 	Configuracion.TAM_CELDA
			)
			var rect = Rect2(
				posicion,
				Vector2(Configuracion.TAM_CELDA, Configuracion.TAM_CELDA)
				)
			draw_rect(rect, Color(0.2, 0.2, 0.25), false, 1.0)
