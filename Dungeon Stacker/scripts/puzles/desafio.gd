class_name Desafio
extends Node2D
## Base de todos los puzles. Un puzle nuevo hereda de esta clase, sobrescribe lo que
## necesite y llama a resolver() cuando se cumple su condición.
##
## Se registra solo como desafío de su sala, igual que los enemigos: las puertas se
## cierran y no se puede cambiar de modo mientras quede alguno sin resolver.

signal resuelto

var esta_resuelto := false

var _habitacion: Habitacion


func _ready() -> void:
	add_to_group("desafio")
	_habitacion = _buscar_habitacion()
	if _habitacion == null:
		return # escena suelta, para probar el puzle sin sala
	# Sala ya resuelta: no se registra y sus elementos aparecen ya resueltos.
	if _habitacion.datos != null and _habitacion.datos.resuelta:
		esta_resuelto = true
		_al_cargar_resuelto()
		return
	_habitacion.registrar_desafio(self)


## Marca el puzle como resuelto. Las puertas se abren si era el último desafío de la sala.
func resolver() -> void:
	if esta_resuelto:
		return
	esta_resuelto = true
	_al_resolver()
	resuelto.emit()
	if _habitacion != null:
		_habitacion.resolver_desafio(self)


## Lo llama el botón de reinicio de la sala. Solo tiene efecto si el puzle sigue sin resolver.
func reiniciar() -> void:
	if esta_resuelto:
		return
	_al_reiniciar()


## Para sobrescribir: qué pasa al resolverse (animación, sonido...).
func _al_resolver() -> void:
	pass


## Para sobrescribir: dejar todo en su estado inicial.
func _al_reiniciar() -> void:
	pass


## Para sobrescribir: mostrar los elementos ya resueltos al volver a una sala completada.
func _al_cargar_resuelto() -> void:
	pass


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
