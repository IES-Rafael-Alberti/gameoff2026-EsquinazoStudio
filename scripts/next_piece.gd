extends Node2D

const Configuracion = preload("res://scripts/configuracion.gd")

var forma: Array = []
var color: Color = Color.WHITE

func actualizar_pieza(nueva_forma: Array, nuevo_color: Color) -> void:
	forma = nueva_forma
	color = nuevo_color
	queue_redraw()

func _draw() -> void:
	for bloque in forma:
		var posicion = Vector2(bloque.x * 20, bloque.y * 20)
		var rect = Rect2(posicion, Vector2(20, 20))
		
		draw_rect(rect, color)
		draw_rect(rect, Color.BLACK, false, 1.0)
