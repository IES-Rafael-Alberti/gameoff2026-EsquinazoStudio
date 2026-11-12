class_name Vida
extends Node
## Componente de vida: lo usan el jugador y los enemigos.

signal danada(cantidad: int)
signal curada(cantidad: int)
## Cualquier cambio de la vida actual o de la máxima (para refrescar la interfaz).
signal cambiada(actual: int, maxima: int)
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
	cambiada.emit(vida, vida_maxima)
	if vida == 0:
		murio.emit()


## Recupera vida sin pasar de la máxima. No resucita: con 0 no hace nada.
func curar(cantidad: int) -> void:
	if not esta_viva() or cantidad <= 0 or vida >= vida_maxima:
		return
	var antes := vida
	vida = mini(vida + cantidad, vida_maxima)
	curada.emit(vida - antes)
	cambiada.emit(vida, vida_maxima)


## Sube la vida máxima. Por defecto el contenedor nuevo viene lleno.
func aumentar_maxima(cantidad: int, rellenar := true) -> void:
	if cantidad <= 0:
		return
	vida_maxima += cantidad
	if rellenar and esta_viva():
		vida += cantidad
	cambiada.emit(vida, vida_maxima)


## Vida completa otra vez (por ejemplo al reiniciar).
func restaurar() -> void:
	vida = vida_maxima
	cambiada.emit(vida, vida_maxima)
