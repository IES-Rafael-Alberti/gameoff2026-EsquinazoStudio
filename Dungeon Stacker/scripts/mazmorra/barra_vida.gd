class_name BarraVida
extends HBoxContainer
## Fila de iconos de vida. Se redibuja cada vez que cambia la vida o la vida máxima.
## Sin texturas asignadas dibuja cuadrados de color como placeholder.
## Si solo se asigna "textura_llena" (la gema), las vidas perdidas usan esa misma gema teñida con
## "tinte_vacio".

@export_group("Sprites")
## Icono de vida. Si no se asigna, se dibuja un cuadrado de color.
@export var textura_llena: Texture2D
## Icono de vida perdida. Si no se asigna, se dibuja un cuadrado de color.
@export var textura_vacia: Texture2D
## Tinte de la gema perdida cuando no hay "textura_vacia" (oscura y algo transparente).
@export var tinte_vacio := Color(0.2, 0.2, 0.2, 0.55)

@export_group("Placeholder")
@export var tamano_icono := Vector2(32, 32)
@export var color_lleno := Color(0.85, 0.15, 0.2)
@export var color_vacio := Color(0.2, 0.2, 0.2, 0.8)

var _vida: Vida

## Conecta la barra a la vida de un personaje y la dibuja.
func configurar(vida: Vida) -> void:
	if _vida != null and _vida.cambiada.is_connected(_refrescar):
		_vida.cambiada.disconnect(_refrescar)
	_vida = vida
	_vida.cambiada.connect(_refrescar)
	_refrescar(_vida.vida, _vida.vida_maxima)

func _refrescar(actual: int, maxima: int) -> void:
	for hijo in get_children():
		remove_child(hijo)
		hijo.queue_free()
	for i in maxima:
		add_child(_crear_icono(i < actual))

func _crear_icono(lleno: bool) -> Control:
	var textura := textura_llena if lleno else textura_vacia
	var teñir := not lleno and textura == null and textura_llena != null
	if teñir:
		textura = textura_llena
	if textura != null:
		var icono := TextureRect.new()
		icono.texture = textura
		if teñir:
			icono.modulate = tinte_vacio
		icono.custom_minimum_size = tamano_icono
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return icono
	var cuadro := ColorRect.new()
	cuadro.color = color_lleno if lleno else color_vacio
	cuadro.custom_minimum_size = tamano_icono
	return cuadro
