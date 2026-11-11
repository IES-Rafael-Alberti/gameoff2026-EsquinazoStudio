class_name Enemigo
extends CharacterBody2D
## Base de todos los enemigos. Un enemigo nuevo hereda de esta clase y sobrescribe _actuar().
##
## Se registra solo como desafío de su sala: las puertas se cierran mientras quede alguno
## y se abren cuando el último muere (desaparece del árbol). Necesita un hijo
## CollisionShape2D para colisionar y para detectar el contacto con el jugador.

signal murio

@export var vida_maxima := 1
## Daño que hace al jugador cada vez que lo toca.
@export var dano_contacto := 1
## Segundos mínimos entre dos daños seguidos al mismo jugador.
@export var intervalo_dano := 1.0

var vida: Vida

var _zona_contacto: Area2D
var _enfriamiento := 0.0


func _ready() -> void:
	add_to_group("enemigo")

	vida = Vida.new()
	vida.vida_maxima = vida_maxima
	add_child(vida)
	vida.murio.connect(_on_vida_murio)

	var habitacion := _buscar_habitacion()
	if habitacion != null:
		# Sala ya despejada: no hay enemigos al volver.
		if habitacion.datos != null and habitacion.datos.resuelta:
			queue_free()
			return
		habitacion.registrar_desafio(self)

	_crear_zona_contacto()


func _physics_process(delta: float) -> void:
	_enfriamiento = maxf(_enfriamiento - delta, 0.0)
	_actuar(delta)
	_aplicar_dano_contacto()


## Comportamiento del enemigo en cada paso de física. La base no hace nada (estático).
func _actuar(_delta: float) -> void:
	pass


## Qué pasa al morir. Aquí puede ir una animación; por defecto desaparece.
func morir() -> void:
	queue_free()


func recibir_dano(cantidad: int) -> void:
	vida.recibir_dano(cantidad)


func _on_vida_murio() -> void:
	murio.emit()
	morir()


func _jugador() -> CharacterBody2D:
	for nodo in get_tree().get_nodes_in_group("jugador"):
		if nodo is CharacterBody2D:
			return nodo
	return null


## Centro del cuerpo del jugador (su origen está en los pies).
func _posicion_de(jugador: CharacterBody2D) -> Vector2:
	if jugador.has_method("centro"):
		return jugador.centro()
	return jugador.global_position


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion


## Un Area2D con la misma forma que el cuerpo, para detectar cuándo toca al jugador.
func _crear_zona_contacto() -> void:
	for hijo in get_children():
		if hijo is CollisionShape2D:
			_zona_contacto = Area2D.new()
			var forma := CollisionShape2D.new()
			forma.shape = hijo.shape
			forma.position = hijo.position
			_zona_contacto.add_child(forma)
			add_child(_zona_contacto)
			return
	push_warning("El enemigo %s no tiene ningún CollisionShape2D: no hará daño por contacto." % name)


func _aplicar_dano_contacto() -> void:
	if _zona_contacto == null or _enfriamiento > 0.0:
		return
	for cuerpo in _zona_contacto.get_overlapping_bodies():
		if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dano_contacto)
			_enfriamiento = intervalo_dano
			return
