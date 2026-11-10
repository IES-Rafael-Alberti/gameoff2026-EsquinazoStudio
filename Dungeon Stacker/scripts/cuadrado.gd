
class_name Cuadrado
extends Node2D

var tamano: int

@onready var fondo: Sprite2D = $Fondo
@onready var borde: Sprite2D = $Borde
@onready var icono: Sprite2D = $Icono

var categoria: CategoriaSala = null

#provisional
@onready var letra: Label = $LetraCategoria

func _ready() -> void:
	icono.visible = icono.texture != null
	_ajustar_sprites()
	letra.visible = false
	_ajustar_letra()
	
func configurar(
	textura_fondo: Texture2D,
	textura_marco: Texture2D,
	nueva_categoria: CategoriaSala = null,
	textura_icono: Texture2D = null
) -> void:
	categoria = nueva_categoria
	fondo.texture = textura_fondo
	borde.texture = textura_marco

	if textura_icono == null and categoria != null:
		textura_icono = categoria.icono

	icono.texture = textura_icono
	icono.visible = textura_icono != null
	letra.text = categoria.letra if categoria != null else ""
	letra.visible = textura_icono == null and categoria != null

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

#borra esto luego
func _ajustar_letra() -> void:
	if letra == null or tamano <= 0:
		return
	letra.size = Vector2(tamano, tamano)
	letra.add_theme_font_size_override("font_size", maxi(int(tamano * 0.6), 12))
	letra.add_theme_color_override("font_outline_color", Color.BLACK)
	letra.add_theme_constant_override("outline_size", 2)
