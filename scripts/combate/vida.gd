class_name Vida
extends Node
## Componente de vida: lo usan el jugador y los enemigos.

signal danada(cantidad: int)
signal murio

@export var vida_maxima := 1

var vida := 1


func _ready() -> void:
	vida = vida_maxima


func esta_viva() -> bool:
	return vida > 0


func recibir_dano(cantidad: int) -> void:
	if not esta_viva() or cantidad <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	danada.emit(cantidad)
	if vida == 0:
		murio.emit()
