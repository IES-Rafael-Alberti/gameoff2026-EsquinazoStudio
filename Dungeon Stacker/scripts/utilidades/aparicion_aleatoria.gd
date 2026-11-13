class_name AparicionAleatoria
extends Node2D
## Pon objetos (trampas, enemigos, pociones, cofres, lo que sea) como hijos de este nodo.
## Al cargar la sala, con "probabilidad_eliminar" % de probabilidad desaparecen TODOS a la
## vez (todo o nada). Si quieres que cada objeto tire su propio dado, ponlo bajo su propio
## componente.
##
## El resultado se decide una sola vez por sala y es siempre el mismo al volver a ella: sale
## de la semilla de la celda (CeldaTablero.semilla) y de la ruta de este nodo en la sala, sin
## guardar nada por objeto. Fuera de una sala (escena suelta) se sortea cada vez.
##
## Cuidado: no pongas aquí objetos de los que dependan otros que se quedan (por ejemplo, una
## placa que necesita un puzle que sí está en la sala).

## Probabilidad (0 a 100) de que los hijos desaparezcan.
@export_range(0.0, 100.0, 0.1) var probabilidad_eliminar := 50.0


func _ready() -> void:
	if not _sale_eliminado():
		return
	for hijo in get_children():
		hijo.queue_free()


func _sale_eliminado() -> bool:
	var habitacion := _buscar_habitacion()
	if habitacion == null or habitacion.datos == null:
		return randf() * 100.0 < probabilidad_eliminar
	var azar := RandomNumberGenerator.new()
	azar.seed = hash([habitacion.datos.semilla, str(habitacion.get_path_to(self))])
	return azar.randf() * 100.0 < probabilidad_eliminar


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
