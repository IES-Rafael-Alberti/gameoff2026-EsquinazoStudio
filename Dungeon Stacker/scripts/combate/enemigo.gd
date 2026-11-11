class_name Enemigo
extends CharacterBody2D
## Base de todos los enemigos. Un enemigo nuevo hereda de esta clase y sobrescribe _actuar().
##
## Se registra solo como desafío de su sala: las puertas se cierran mientras quede alguno
## y se abren cuando el último muere (desaparece del árbol). Necesita un hijo
## CollisionShape2D para colisionar y para detectar el contacto con el jugador.
##
## Los enemigos puestos en la sala desaparecen si la sala ya está despejada. Los invocados
## (cofre falso...) llevan invocado = true: si salen con la sala ya despejada no cuentan
## como desafío (las puertas no se cierran) y desaparecen con la sala al salir de ella.
## Además, al aparecer se quedan bloqueados unos instantes (bloqueo_invocado): no se mueven,
## no hacen daño y no reciben daño, para que el jugador no se los encuentre de golpe.

signal murio

@export var vida_maxima := 1
## Daño que hace al jugador cada vez que lo toca.
@export var dano_contacto := 1
## Segundos mínimos entre dos daños seguidos al mismo jugador.
@export var intervalo_dano := 1.0
## Los voladores ignoran los peligros del suelo (pinchos, sierras...).
@export var volador := false

## Segundos que se queda quieto, inofensivo e invulnerable al aparecer invocado.
## No afecta a los enemigos puestos en la sala.
@export var bloqueo_invocado := 0.5

## Lo pone a true quien lo crea por código (cofre falso...) ANTES de añadirlo a la escena.
var invocado := false

var vida: Vida

var _zona_contacto: Area2D
var _enfriamiento := 0.0
var _bloqueo := 0.0

func _ready() -> void:
	add_to_group("enemigo")
	if invocado:
		_bloqueo = bloqueo_invocado

	vida = Vida.new()
	vida.vida_maxima = vida_maxima
	add_child(vida)
	vida.murio.connect(_on_vida_murio)

	var habitacion := _buscar_habitacion()
	if habitacion != null:
		var sala_despejada: bool = habitacion.datos != null and habitacion.datos.resuelta
		if not sala_despejada:
			habitacion.registrar_desafio(self)
		elif not invocado:
			# Sala ya despejada: no hay enemigos al volver.
			queue_free()
			return
		# Invocado con la sala despejada: no es desafío y se va con la sala al salir.
	_crear_zona_contacto()

func _physics_process(delta: float) -> void:
	if _bloqueo > 0.0:
		_bloqueo -= delta
		return # bloqueado: ni se mueve ni hace daño
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
	if _bloqueo > 0.0:
		return # invulnerable mientras está bloqueado
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
	push_warning("El enemigo %s no tiene ningún CollisionShape2D: no hará daño por contacto." % name)

func _aplicar_dano_contacto() -> void:
	if _zona_contacto == null or _enfriamiento > 0.0:
		return
	for cuerpo in _zona_contacto.get_overlapping_bodies():
		if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dano_contacto)
			_enfriamiento = intervalo_dano
			return
