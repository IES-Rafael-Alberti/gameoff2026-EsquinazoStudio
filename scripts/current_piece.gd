extends Node2D

const Configuracion = preload("res://scripts/configuracion.gd")

var forma: Array = []
var posicion: Vector2i = Vector2i.ZERO
var color: Color = Color.WHITE
var visible_pieza: bool = false

func actualizar_pieza(
	nueva_forma: Array,
	nueva_posicion: Vector2i,
	nuevo_color: Color,
	mostrar: bool
) -> void:
	forma = nueva_forma
	posicion = nueva_posicion
	color = nuevo_color
	visible_pieza = mostrar
	queue_redraw()


func _draw() -> void:
	if not visible_pieza:
		return

	for bloque in forma:
		var celda = posicion + bloque
		var rect = Rect2(
			Vector2(celda.x * Configuracion.TAM_CELDA, celda.y * Configuracion.TAM_CELDA),
			Vector2(Configuracion.TAM_CELDA, Configuracion.TAM_CELDA)
		)

		draw_rect(rect, color)
		draw_rect(rect, Color(0, 0, 0, 0.25), false, 1.5)
