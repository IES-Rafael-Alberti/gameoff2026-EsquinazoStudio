class_name BaldosaRota
extends Area2D

signal rota(baldosa: BaldosaRota)

const TAM_TILE := 512
const ATLAS_VACIO := Vector2i(5, 1)

var _jugador_dentro := false
var _rota := false

@onready var _sprite: Sprite2D = $Sprite2D

var _textura_rota: Texture2D
var _textura_vacio: Texture2D

func _ready() -> void:
	add_to_group("baldosa_rota")
	collision_layer = 0
	collision_mask = 2 # capa del jugador
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_textura_rota = _sprite.texture
	if _textura_rota is AtlasTexture:
		var vacio := AtlasTexture.new()
		vacio.atlas = (_textura_rota as AtlasTexture).atlas
		vacio.region = Rect2(
			ATLAS_VACIO.x * TAM_TILE,
			ATLAS_VACIO.y * TAM_TILE,
			TAM_TILE,
			TAM_TILE
		)
		vacio.filter_clip = true
		_textura_vacio = vacio

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		_jugador_dentro = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("jugador") or not _jugador_dentro:
		return
	_jugador_dentro = false
	if _rota:
		return
	_rota = true
	if _textura_vacio != null:
		_sprite.texture = _textura_vacio
	rota.emit(self)

## La sala la devuelve a su estado inicial.
func restaurar() -> void:
	_rota = false
	_jugador_dentro = false
	_sprite.texture = _textura_rota
