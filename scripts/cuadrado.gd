
class_name Cuadrado
extends Node2D

var tamano: int

@onready var fondo: Sprite2D = $Fondo
@onready var borde: Sprite2D = $Borde
@onready var icono: Sprite2D = $Icono

var categoria: Catalogo.Categoria = Catalogo.Categoria

func _ready() -> void:
	icono.visible = icono.texture != null
	_ajustar_sprites()

func configurar(
	textura_fondo: Texture2D,
	textura_marco: Texture2D,
	nueva_categoria: Catalogo.Categoria = Catalogo.Categoria,
	textura_icono: Texture2D = null
) -> void:
	categoria = nueva_categoria
	fondo.texture = textura_fondo
	borde.texture = textura_marco
	icono.texture = textura_icono
	icono.visible = textura_icono != null
	_ajustar_sprites()

func poner_en_celda(celda: Vector2i) -> void:
	position = Vector2(celda) * tamano

func _ajustar_sprites() -> void:
	_ajustar_sprite(fondo)
	_ajustar_sprite(borde)
	_ajustar_sprite(icono)

func _ajustar_sprite(sprite: Sprite2D) -> void:
	if sprite.texture == null:
		return

	var medida: Vector2 = sprite.texture.get_size()
	if medida.x <= 0.0 or medida.y <= 0.0:
		return

	sprite.scale = Vector2(tamano / medida.x, tamano / medida.y)
