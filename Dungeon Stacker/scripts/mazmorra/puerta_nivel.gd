class_name PuertaNivel
extends Area2D
## Puerta de los vestíbulos que termina el nivel al tocarla. Escena propia (puerta_nivel.tscn):
## Area2D en la raíz con dos Sprite2D (la puerta ocupa dos casillas: la mitad izquierda tal cual
## y la derecha reflejada en horizontal) y un CollisionShape2D. En el inspector, la máscara de
## colisión debe incluir la capa del jugador, y la señal body_entered de la raíz se conecta a
## _on_body_entered.
## El aspecto (abierta o cerrada) lo decide el vestíbulo con establecer_abierta(); no depende de
## "activa", así que la puerta no cambia de aspecto al tocarla.
## El vestíbulo inferior la coloca también (decorativa, con activa = false); solo funciona
## la del vestíbulo superior.

## El jugador la ha tocado estando activa.
signal tocada

@export_group("Aspecto")
## Mitad izquierda de la puerta (se ve tal cual).
@export var sprite_izquierdo: Sprite2D
## Mitad derecha: debe tener "Flip H" activado en el inspector para verse reflejada.
@export var sprite_derecho: Sprite2D
## Textura de la puerta abierta.
@export var textura_abierta: Texture2D
## Textura de la puerta cerrada.
@export var textura_cerrada: Texture2D

var _abierta := true

## Si se desactiva no reacciona al jugador. Lo pone el vestíbulo que la instancia.
@export var activa := true:
	set(valor):
		activa = valor
		# Diferido: también se cambia desde la señal body_entered, donde el motor lo bloquea.
		set_deferred(&"monitoring", valor)

func _on_body_entered(cuerpo: Node2D) -> void:
	if not activa or not cuerpo.is_in_group("jugador"):
		return
	activa = false # una sola vez
	# Diferido: quien la escucha cambia de escena, y eso no se puede hacer en un callback de física.
	tocada.emit.call_deferred()

func _ready() -> void:
	_aplicar_aspecto()

## Pone la puerta abierta o cerrada (solo el aspecto; si funciona lo decide "activa").
func establecer_abierta(abierta: bool) -> void:
	_abierta = abierta
	if is_node_ready():
		_aplicar_aspecto()

func _aplicar_aspecto() -> void:
	var textura := textura_abierta if _abierta else textura_cerrada
	if textura == null:
		return
	for sprite in [sprite_izquierdo, sprite_derecho]:
		if sprite != null:
			sprite.texture = textura

## Voltea en vertical los dos sprites (solo el dibujo, no la zona de colisión).
func reflejar_sprites() -> void:
	for sprite in [sprite_izquierdo, sprite_derecho]:
		if sprite != null:
			sprite.flip_v = true
