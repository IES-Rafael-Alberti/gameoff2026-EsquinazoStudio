class_name BarraVida
extends Control
## Indicador de vida con gemas colocadas a mano en el editor: enciende (muestra) las primeras N
## gemas según la vida actual y apaga (oculta) el resto.
## Las gemas pueden ser cualquier nodo visible (TextureRect, Sprite2D...) y estar donde quieras,
## por ejemplo sobre la corona. Si hay más gemas que vida máxima, las que sobran quedan apagadas.

## Las gemas, en orden: la primera se apaga la última.
@export var gemas: Array[CanvasItem] = []

var _vida: Vida


## Conecta la barra a la vida de un personaje y la dibuja.
func configurar(vida: Vida) -> void:
	if _vida != null and _vida.cambiada.is_connected(_refrescar):
		_vida.cambiada.disconnect(_refrescar)
	_vida = vida
	_vida.cambiada.connect(_refrescar)
	_refrescar(_vida.vida, _vida.vida_maxima)


func _refrescar(actual: int, _maxima: int) -> void:
	for i in gemas.size():
		if gemas[i] != null:
			gemas[i].visible = i < actual
