extends Node2D

const ESCENA_CUADRADO = preload("res://scenes/cuadrado.tscn")
var Configuracion: Configuracion_Tablero

var forma: Array = []
var posicion: Vector2i = Vector2i.ZERO
var textura_fondo: Texture2D
var textura_marco: Texture2D
var categorias: Array = []
var visible_pieza: bool = false

var _cuadrados: Array = []


func actualizar_pieza(
	nueva_forma: Array,
	nueva_posicion: Vector2i,
	nueva_textura_fondo: Texture2D,
	nueva_textura_marco: Texture2D,
	nuevas_categorias: Array,
	mostrar: bool
) -> void:
	forma = nueva_forma
	posicion = nueva_posicion
	textura_fondo = nueva_textura_fondo
	textura_marco = nueva_textura_marco
	categorias = nuevas_categorias
	visible_pieza = mostrar

	_asegurar_cuadrados(forma.size())
	_actualizar_cuadrados()


func _asegurar_cuadrados(cantidad: int) -> void:
	while _cuadrados.size() < cantidad:
		var cuadrado = ESCENA_CUADRADO.instantiate()
		cuadrado.tamano = Configuracion.TAM_CELDA
		add_child(cuadrado)
		_cuadrados.append(cuadrado)


func _actualizar_cuadrados() -> void:
	for i in _cuadrados.size():
		var cuadrado = _cuadrados[i]

		if not visible_pieza or i >= forma.size():
			cuadrado.visible = false
			continue

		var categoria = Cuadrado.Categoria.A
		if i < categorias.size():
			categoria = categorias[i]

		cuadrado.visible = true
		cuadrado.configurar(textura_fondo, textura_marco, categoria)
		cuadrado.poner_en_celda(posicion + forma[i])
