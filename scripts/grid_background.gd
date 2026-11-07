extends Node2D

# Cuando es directamente el padre
#var Configuracion = get_parent().Configuracion
# Cuando es la raiz (en este caso Main)
#var Configuracion = get_tree().root.Configuracion
func _draw():
	var Configuracion = get_tree().current_scene.Configuracion	
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
			draw_rect(rect, Color(0.2, 0.2, 0.25), false, 1.0)
