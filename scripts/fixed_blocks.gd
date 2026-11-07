extends Node2D

const ESCENA_CUADRADO = preload("res://scenes/cuadrado.tscn")

var tablero: Array = []
var textura_marco: Texture2D
var _cuadrados: Array = []


func actualizar_tablero(nuevo_tablero: Array) -> void:
	tablero = nuevo_tablero
	_actualizar_cuadrados()


func _actualizar_cuadrados() -> void:
	var posiciones: Array = []
	var celdas: Array = []
	var Configuracion = get_tree().current_scene.Configuracion
	if tablero.size() >= Configuracion.FILAS:
		for y in range(Configuracion.FILAS):
			for x in range(Configuracion.COLUMNAS):
				var celda = tablero[y][x]
				if celda != null:
					posiciones.append(Vector2i(x, y))
					celdas.append(celda)

	_asegurar_cuadrados(posiciones.size())

	for i in _cuadrados.size():
		var cuadrado = _cuadrados[i]

		if i >= posiciones.size():
			cuadrado.visible = false
			continue

		var celda = celdas[i]
		cuadrado.visible = true
		cuadrado.configurar(celda.textura_fondo, textura_marco, celda.categoria)
		cuadrado.poner_en_celda(posiciones[i])


func _asegurar_cuadrados(cantidad: int) -> void:
	var Configuracion = get_tree().current_scene.Configuracion
	while _cuadrados.size() < cantidad:
		var cuadrado = ESCENA_CUADRADO.instantiate()
		cuadrado.tamano = Configuracion.TAM_CELDA
		add_child(cuadrado)
		_cuadrados.append(cuadrado)
