class_name Flecha
extends Area2D
## Flecha de un lanzaflechas. Vuela recta y se rompe al contacto con cualquier cosa que
## detecte su máscara (muros, cajas, sierras, trampas, jugador, enemigos...). Si lo que toca
## es el jugador o un enemigo, además le hace daño. No daña ni se rompe con su lanzador.
##
## Quien la crea rellena direccion, emisor y (si quiere) dano o velocidad ANTES de añadirla
## a la escena, como hace el cofre falso con los enemigos.
## En el editor: sin capa y máscara con las capas 1 a 6.

## Se emite al romperse.
signal rota

@export var dano := 1
## Píxeles por segundo.
@export var velocidad := 240.0
## Distancia máxima antes de romperse sola. 0 = sin límite.
@export var alcance_maximo := 0.0

@export_group("Rotura")
## Segundos que se ve rota antes de desaparecer. 0 = desaparece al instante.
@export var duracion_rotura := 0.1

@export_group("Sprites")
@export var sprite_flecha: Texture2D
@export var sprite_rota: Texture2D
## Escala de los sprites (0.125 para arte de 512 px en casillas de 64).
@export var escala_sprites := 0.125

## Dirección de vuelo (la pone quien la crea).
var direccion := Vector2.RIGHT
## Lanzador que la disparó: no la rompe ni se daña con ella.
var emisor: Node

var _recorrido := 0.0
var _rota := false

@onready var _sprite: Sprite2D = $Sprite
## Dibujo de relleno (opcional): se oculta en cuanto hay sprite_flecha.
@onready var _provisional: CanvasItem = get_node_or_null("Provisional") as CanvasItem


func _ready() -> void:
	rotation = direccion.angle()
	_sprite.scale = Vector2.ONE * escala_sprites
	_poner_sprite(false)
	body_entered.connect(_on_cuerpo_entro)
	area_entered.connect(_on_area_entro)


func _physics_process(delta: float) -> void:
	if _rota:
		return
	var paso := direccion * velocidad * delta
	position += paso
	_recorrido += paso.length()
	if alcance_maximo > 0.0 and _recorrido >= alcance_maximo:
		romper()


func _on_cuerpo_entro(cuerpo: Node2D) -> void:
	if _rota or _es_del_emisor(cuerpo):
		return
	if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_dano"):
		cuerpo.recibir_dano(dano, global_position)
	elif cuerpo is Enemigo:
		cuerpo.recibir_dano(dano)
	romper()


func _on_area_entro(area: Area2D) -> void:
	if _rota or _es_del_emisor(area):
		return
	romper()


func romper() -> void:
	if _rota:
		return
	_rota = true
	set_deferred("monitoring", false)
	_poner_sprite(true)
	rota.emit()
	if duracion_rotura > 0.0:
		await get_tree().create_timer(duracion_rotura).timeout
		if not is_inside_tree():
			return
	queue_free()


func _es_del_emisor(nodo: Node) -> bool:
	return is_instance_valid(emisor) and (nodo == emisor or emisor.is_ancestor_of(nodo))


func _poner_sprite(esta_rota: bool) -> void:
	var textura := sprite_rota if esta_rota and sprite_rota != null else sprite_flecha
	_sprite.texture = textura
	if _provisional != null:
		_provisional.visible = sprite_flecha == null and not esta_rota
