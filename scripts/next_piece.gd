extends Node2D

const Configuracion = preload("res://scripts/configuracion.gd")

var forma: Array = []
var color: Color = Color.WHITE

func actualizar_pieza(nueva_forma: Array, nuevo_color: Color) -> void:
	forma = nueva_forma
	color = nuevo_color
	queue_redraw()

func _draw() -> void:
	if forma.is_empty():
		return

	var min_x: int = forma[0].x
	var max_x: int = forma[0].x
	var min_y: int = forma[0].y
	var max_y: int = forma[0].y

	for bloque in forma:
		min_x = min(min_x, bloque.x)
		max_x = max(max_x, bloque.x)
		min_y = min(min_y, bloque.y)
		max_y = max(max_y, bloque.y)

	var tam = Configuracion.TAM_CELDA
	var ancho = (max_x - min_x + 1) * tam
	var alto = (max_y - min_y + 1) * tam
	var origen = Vector2(-ancho / 2.0, -alto / 2.0)

	for bloque in forma:
		var posicion = Vector2(bloque.x - min_x, bloque.y - min_y) * tam + origen
		var rect = Rect2(posicion, Vector2(tam, tam))

		draw_rect(rect, color)
		draw_rect(rect, Color.BLACK, false, 1.0)
