class_name Barreras
extends Node2D
## Dibuja la textura de barrera encima de cada posición con barrera activa. Va en la escena del
## Tetris como hijo de Board, justo detrás de FixedBlocks, para quedar encima de las casillas
## colocadas pero por debajo de la pieza que cae y de su fantasma.

var _posiciones: Array[Vector2i] = []

func actualizar(posiciones: Array[Vector2i]) -> void:
	_posiciones = posiciones
	queue_redraw()

func _draw() -> void:
	var tetris := Tetris.de(self)
	if tetris == null or tetris.Configuracion == null:
		return
	var textura: Texture2D = tetris.Configuracion.TEXTURA_BARRERA
	if textura == null:
		return
	var tam: int = tetris.Configuracion.TAM_CELDA
	for pos in _posiciones:
		draw_texture_rect(textura, Rect2(Vector2(pos) * tam, Vector2(tam, tam)), false)
