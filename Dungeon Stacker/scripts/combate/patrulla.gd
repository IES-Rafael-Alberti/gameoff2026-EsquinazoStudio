class_name Patrulla
extends CharacterBody2D
## Patrulla inmortal: recorre una ruta de puntos sin parar y hace daño al jugador por
## contacto. No tiene vida y no es un Enemigo, así que ni el ataque del jugador ni las
## trampas le hacen nada (las flechas sí se rompen contra ella).
##
## Ruta: su posición inicial es el punto 0 y sus hijos Marker2D son los puntos 1, 2, 3... en
## el orden del árbol. Va en línea recta de uno a otro y NO esquiva ni colisiona con nada:
## el recorrido lo pones tú.
## En el editor: capa Enemigos (4), sin máscara. Necesita un hijo CollisionShape2D para
## detectar el contacto con el jugador.

enum Recorrido { CICLO, IDA_Y_VUELTA }

## Ciclo: tras el último punto vuelve al punto 0 y repite siempre en el mismo sentido.
## Ida y vuelta: llega al último punto y desanda el camino hasta el 0.
@export var recorrido := Recorrido.CICLO
## Píxeles por segundo.
@export var velocidad := 60.0
## Daño que hace al jugador cada vez que lo toca.
@export var dano_contacto := 1
## Segundos mínimos entre dos daños seguidos al jugador.
@export var intervalo_dano := 1.0

@export_group("Sala")
## Si cuenta como desafío: las puertas se cierran mientras exista. Como es inmortal, solo
## tiene sentido junto a otros desafíos que sí se puedan resolver, o la sala no se acabaría.
@export var es_desafio := false
## Si desaparece para siempre cuando la sala se da por resuelta. Al volver a una sala ya
## resuelta tampoco aparece.
@export var desaparece_al_resolver_sala := false

var _puntos: Array[Vector2] = []
var _indice := 1 # punto al que se dirige
var _sentido := 1
var _zona_contacto: Area2D
var _enfriamiento := 0.0
var _habitacion: Habitacion


func _ready() -> void:
	_habitacion = _buscar_habitacion()
	if _habitacion != null:
		var resuelta: bool = _habitacion.datos != null and _habitacion.datos.resuelta
		if desaparece_al_resolver_sala and resuelta:
			queue_free()
			return
		if es_desafio and not resuelta:
			_habitacion.registrar_desafio(self)
		if desaparece_al_resolver_sala:
			_habitacion.desafios_resueltos.connect(morir)
	_recoger_puntos()
	_crear_zona_contacto()


func _physics_process(delta: float) -> void:
	_enfriamiento = maxf(_enfriamiento - delta, 0.0)
	_mover(delta)
	_aplicar_dano_contacto()


## Qué pasa al desaparecer. Aquí puede ir una animación; por defecto se borra sin más.
func morir() -> void:
	queue_free()


# Los puntos se guardan una sola vez como posiciones globales: los Marker2D son hijos y se
# mueven con la patrulla, pero ya no hace falta leerlos.
func _recoger_puntos() -> void:
	_puntos.append(global_position)
	for hijo in get_children():
		if hijo is Marker2D:
			_puntos.append(hijo.global_position)
	if _puntos.size() < 2:
		push_warning("La patrulla %s necesita al menos un Marker2D hijo: no se moverá." % name)


func _mover(delta: float) -> void:
	if _puntos.size() < 2:
		return
	var objetivo := _puntos[_indice]
	global_position = global_position.move_toward(objetivo, velocidad * delta)
	if global_position.is_equal_approx(objetivo):
		_siguiente_punto()


func _siguiente_punto() -> void:
	match recorrido:
		Recorrido.CICLO:
			_indice = (_indice + 1) % _puntos.size()
		Recorrido.IDA_Y_VUELTA:
			var siguiente := _indice + _sentido
			if siguiente < 0 or siguiente >= _puntos.size():
				_sentido = -_sentido
			_indice += _sentido


func _crear_zona_contacto() -> void:
	for hijo in get_children():
		if hijo is CollisionShape2D:
			_zona_contacto = Area2D.new()
			_zona_contacto.collision_layer = 0
			_zona_contacto.collision_mask = Capas.JUGADOR
			var forma := CollisionShape2D.new()
			forma.shape = hijo.shape
			forma.position = hijo.position
			_zona_contacto.add_child(forma)
			add_child(_zona_contacto)
			return
	push_warning("La patrulla %s no tiene ningún CollisionShape2D: no hará daño por contacto." % name)


func _aplicar_dano_contacto() -> void:
	if _zona_contacto == null or _enfriamiento > 0.0:
		return
	for cuerpo in _zona_contacto.get_overlapping_bodies():
		if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dano_contacto)
			_enfriamiento = intervalo_dano
			return


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
