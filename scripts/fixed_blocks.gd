extends Node2D

const Configuracion = preload("res://scripts/configuracion.gd")

var tablero: Array = []

func actualizar_tablero(nuevo_tablero: Array) -> void:
	tablero = nuevo_tablero
	queue_redraw()

func _draw() -> void:
	if tablero.size() < Configuracion.FILAS:
		return

	for y in range(Configuracion.FILAS):
		for x in range(Configuracion.COLUMNAS):
			if typeof(tablero[y][x]) == TYPE_COLOR:
				var posicion = Vector2(
					x * Configuracion.TAM_CELDA,
					y * Configuracion.TAM_CELDA
				)
				var rect = Rect2(
					posicion,
					Vector2(
						Configuracion.TAM_CELDA,
						Configuracion.TAM_CELDA
					)
				)

				draw_rect(rect, tablero[y][x])
				draw_rect(rect, Color(0, 0, 0, 0.25),
					false, 1.5)
