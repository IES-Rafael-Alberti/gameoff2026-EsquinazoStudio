class_name Mina
extends Node2D
## Mina: cuando el jugador se acerca empieza una cuenta atrás (los 7 sprites de la bomba
## mientras parpadea en rojo) y explota en un área de 3x3 casillas (rango 1, siempre).
## La explosión daña al jugador y a los enemigos que andan (lo hace el nodo Explosion,
## que es un Peligro). Después la mina se borra de la escena.
##
## Al explotar se anota en la celda de su sala (CeldaTablero.minas_explotadas), así que
## no vuelve a aparecer cuando se recarga la sala.
##
## Estructura esperada: Sprite (Sprite2D), Deteccion (Area2D con un CollisionShape2D
## circular) y Explosion (Area2D con el script peligro.gd y un rectángulo de 192x192).

## Se emite al explotar, antes de borrarse.
signal explotada

## Lado de una casilla en píxeles.
const TAM_CELDA := 64.0

@export_group("Daño")
## Daño de la explosión.
@export var dano := 1

@export_group("Activación")
## Distancia (píxeles) a la que el jugador activa la mina.
@export var radio_deteccion := 96.0
## Segundos desde que se activa hasta que explota.
@export var duracion_cuenta_atras := 1.5
## Cuántas veces parpadea en rojo durante la cuenta atrás. 0 = no parpadea.
@export var parpadeos := 2
## Color por el que cambia el modulate en cada parpadeo.
@export var color_parpadeo := Color(1, 0.2, 0.2)

@export_group("Explosión")
## Segundos que dura la explosión antes de borrarse la mina.
@export var duracion_explosion := 0.4
## Segundos que se ve cada uno de los dos sprites de la explosión antes de cambiar al otro.
@export var intervalo_explosion := 0.1

@export_group("Sprites")
## Los 7 sprites de la bomba, en orden.
@export var fotogramas_bomba: Array[Texture2D]
## Los 2 sprites de la explosión (el 8 y el 9 de la hoja). Se repiten en las 9 casillas.
@export var fotogramas_explosion: Array[Texture2D]
## Escala de los sprites (0.125 para arte de 512 px en casillas de 64).
@export var escala_sprites := 0.125

var _activada := false
var _habitacion: Habitacion
var _sprites_explosion: Node2D
var _casillas_explosion: Array[Sprite2D] = []

@onready var _sprite: Sprite2D = $Sprite
@onready var _deteccion: Area2D = $Deteccion
@onready var _explosion: Peligro = $Explosion


func _ready() -> void:
	_habitacion = _buscar_habitacion()
	# Esta mina ya explotó en una visita anterior: no vuelve a salir.
	if _habitacion != null and _habitacion.datos != null \
			and _habitacion.datos.minas_explotadas.has(_clave()):
		queue_free()
		return

	# La forma de la escena se comparte entre todas las minas: se duplica antes de cambiarla.
	var colision := $Deteccion/CollisionShape2D as CollisionShape2D
	var forma := (colision.shape as CircleShape2D).duplicate() as CircleShape2D
	forma.radius = radio_deteccion
	colision.shape = forma

	_explosion.dano = dano
	_explosion.activo = false

	_sprite.scale = Vector2.ONE * escala_sprites
	_poner_fotograma_bomba(0)
	_crear_sprites_explosion()

	_deteccion.body_entered.connect(_on_cuerpo_entro)


func _on_cuerpo_entro(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("jugador"):
		_activar()


func _activar() -> void:
	if _activada:
		return
	_activada = true
	_deteccion.set_deferred("monitoring", false)
	await _cuenta_atras()
	if not is_inside_tree():
		return
	await _explotar()


## Reproduce los 7 sprites repartidos en toda la cuenta atrás y parpadea en rojo a la vez.
func _cuenta_atras() -> void:
	var total := fotogramas_bomba.size()
	var animacion := create_tween()
	if total > 0:
		animacion.tween_method(
			func(valor: float) -> void: _poner_fotograma_bomba(mini(int(valor), total - 1)),
			0.0, float(total), duracion_cuenta_atras
		)
	else:
		animacion.tween_interval(duracion_cuenta_atras)

	if parpadeos > 0:
		var mitad := duracion_cuenta_atras / (parpadeos * 2.0)
		var parpadeo := create_tween()
		for i in parpadeos:
			parpadeo.tween_property(_sprite, "modulate", color_parpadeo, mitad)
			parpadeo.tween_property(_sprite, "modulate", Color.WHITE, mitad)

	await animacion.finished
	_sprite.modulate = Color.WHITE


func _explotar() -> void:
	# Se anota al empezar la explosión: aunque el jugador salga de la sala, no vuelve.
	if _habitacion != null and _habitacion.datos != null:
		_habitacion.datos.minas_explotadas.append(_clave())
	_sprite.visible = false
	_sprites_explosion.visible = true
	_explosion.activo = true
	explotada.emit()

	var transcurrido := 0.0
	var indice := 0
	while transcurrido < duracion_explosion:
		_poner_fotograma_explosion(indice % maxi(fotogramas_explosion.size(), 1))
		await get_tree().create_timer(intervalo_explosion).timeout
		if not is_inside_tree():
			return
		transcurrido += intervalo_explosion
		indice += 1
	queue_free()


## Identifica esta mina dentro de su sala: su posición. Cada celda guarda su propia lista.
func _clave() -> Vector2i:
	return Vector2i(global_position.round())


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion


## Las 9 casillas del 3x3 (la central es la de la mina), todas con el mismo sprite a la vez.
func _crear_sprites_explosion() -> void:
	_sprites_explosion = Node2D.new()
	_sprites_explosion.visible = false
	add_child(_sprites_explosion)
	for fila in range(-1, 2):
		for columna in range(-1, 2):
			var casilla := Sprite2D.new()
			casilla.scale = Vector2.ONE * escala_sprites
			casilla.position = Vector2(columna, fila) * TAM_CELDA
			_sprites_explosion.add_child(casilla)
			_casillas_explosion.append(casilla)


func _poner_fotograma_bomba(indice: int) -> void:
	if indice < fotogramas_bomba.size():
		_sprite.texture = fotogramas_bomba[indice]


func _poner_fotograma_explosion(indice: int) -> void:
	if indice >= fotogramas_explosion.size():
		return
	for casilla in _casillas_explosion:
		casilla.texture = fotogramas_explosion[indice]
