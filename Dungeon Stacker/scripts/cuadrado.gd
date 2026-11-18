class_name Cuadrado
extends Node2D

## Lado de la marca "solo horizontal" respecto al de la casilla.
const ESCALA_MARCA := 0.4

var tamano: int

@onready var fondo: Sprite2D = $Fondo
@onready var borde: Sprite2D = $Borde
@onready var icono: Sprite2D = $Icono
## Marca que avisa de que las salas de esta casilla son solo horizontales (puertas Este y Oeste).
## Su textura se asigna en cuadrado.tscn; si no hay nodo o textura, no se ve nada.
@onready var marca_horizontal: Sprite2D = get_node_or_null("MarcaHorizontal") as Sprite2D

var categoria: CategoriaSala = null

#provisional
@onready var letra: Label = $LetraCategoria

func _ready() -> void:
	icono.visible = icono.texture != null
	if marca_horizontal != null:
		marca_horizontal.visible = false
	_ajustar_sprites()
	letra.visible = false
	_ajustar_letra()
	
func configurar(
	textura_fondo: Texture2D,
	textura_marco: Texture2D,
	nueva_categoria: CategoriaSala = null,
	textura_icono: Texture2D = null,
	solo_horizontal := false
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
	if marca_horizontal != null:
		marca_horizontal.visible = solo_horizontal and marca_horizontal.texture != null

	_ajustar_sprites()

func poner_en_celda(celda: Vector2i) -> void:
	position = Vector2(celda) * tamano

func _ajustar_sprites() -> void:
	_ajustar_sprite(fondo)
	_ajustar_sprite(borde)
	_ajustar_sprite(icono)
	_ajustar_marca()

## La marca va pequeña, centrada en la parte de abajo de la casilla.
func _ajustar_marca() -> void:
	if marca_horizontal == null or marca_horizontal.texture == null:
		return
	var medida: Vector2 = marca_horizontal.texture.get_size()
	if medida.x <= 0.0 or medida.y <= 0.0:
		return
	var lado := tamano * ESCALA_MARCA
	marca_horizontal.scale = Vector2(lado / medida.x, lado / medida.y)
	marca_horizontal.position = Vector2((tamano - lado) * 0.5, tamano - lado - tamano * 0.04)

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
