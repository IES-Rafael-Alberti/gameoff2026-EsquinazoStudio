extends Node2D

const ESCENA_CUADRADO = preload("res://scenes/cuadrado.tscn")

var forma: Array = []
var textura_fondo: Texture2D
var textura_marco: Texture2D
var categorias: Array = []

var _cuadrados: Array = []


func actualizar_pieza(
	nueva_forma: Array,
	nueva_textura_fondo: Texture2D,
	nueva_textura_marco: Texture2D,
	nuevas_categorias: Array
) -> void:
	forma = nueva_forma
	textura_fondo = nueva_textura_fondo
	textura_marco = nueva_textura_marco
	categorias = nuevas_categorias

	_asegurar_cuadrados(forma.size())
	_actualizar_cuadrados()


func _asegurar_cuadrados(cantidad: int) -> void:
	var Configuracion = get_tree().current_scene.Configuracion
	while _cuadrados.size() < cantidad:
		var cuadrado = ESCENA_CUADRADO.instantiate()
		cuadrado.tamano = Configuracion.TAM_CELDA
		add_child(cuadrado)
		_cuadrados.append(cuadrado)


func _actualizar_cuadrados() -> void:
	if forma.is_empty():
		for cuadrado in _cuadrados:
			cuadrado.visible = false
		return
	var Configuracion = get_tree().current_scene.Configuracion
	var min_x: int = forma[0].x
	var max_x: int = forma[0].x
	var min_y: int = forma[0].y
	var max_y: int = forma[0].y

	for bloque in forma:
		min_x = min(min_x, bloque.x)
		max_x = max(max_x, bloque.x)
		min_y = min(min_y, bloque.y)
		max_y = max(max_y, bloque.y)

	var tam = Configuracion.TAM_CELDA
	var ancho = (max_x - min_x + 1) * tam
	var alto = (max_y - min_y + 1) * tam
	var origen = Vector2(-ancho / 2.0, -alto / 2.0)

	for i in _cuadrados.size():
		var cuadrado = _cuadrados[i]

		if i >= forma.size():
			cuadrado.visible = false
			continue

		var categoria = Cuadrado.Categoria.A
		if i < categorias.size():
			categoria = categorias[i]

		var bloque = forma[i]
		cuadrado.visible = true
		cuadrado.configurar(textura_fondo, textura_marco, categoria)
		cuadrado.position = origen + Vector2(bloque.x - min_x, bloque.y - min_y) * tam
