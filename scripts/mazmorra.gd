class_name Mazmorra
extends Node2D

const ESCENA_HABITACION := preload("res://scenes/Habitacion_Base.tscn")
## Centro de la habitación, en coordenadas de la propia habitación.
const CENTRO_HABITACION := Vector2(928, 512)

## Habitaciones de la mazmorra: Vector2i(x, y) -> CeldaTablero (categoría y bioma).
## La forma de la mazmorra es la forma que dejan las piezas en el tablero.
var celdas := {}
var _columnas := 0
var _filas := 0
var celda_actual := Vector2i.ZERO
var habitacion_actual: Habitacion

var _etiqueta: Label # provisional: muestra en qué sala estás

@onready var jugador: CharacterBody2D = $Jugador


func _ready() -> void:
	_crear_etiqueta()
	_etiqueta.visible = false


## Texto provisional en pantalla con la celda y la categoría de la sala actual.
func _crear_etiqueta() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)
	_etiqueta = Label.new()
	_etiqueta.position = Vector2(10, 10)
	_etiqueta.add_theme_font_size_override("font_size", 28)
	_etiqueta.add_theme_constant_override("outline_size", 8)
	capa.add_child(_etiqueta)

func set_activa(activa: bool) -> void:
	if _etiqueta != null:
		_etiqueta.visible = activa

## Lee una matriz como la de tablero.matriz: null = sin habitación, CeldaTablero = habitación.
func generar(matriz: Array) -> void:
	celdas.clear()
	_filas = matriz.size()
	_columnas = 0 if _filas == 0 else matriz[0].size()
	for y in _filas:
		for x in matriz[y].size():
			if matriz[y][x] != null:
				celdas[Vector2i(x, y)] = matriz[y][x]


## Sustituye la habitación cargada por la de esta celda y coloca al jugador.
func cargar_habitacion(celda: Vector2i, posicion_jugador: Vector2 = CENTRO_HABITACION) -> void:
	if not hay_habitacion(celda):
		push_warning("No hay habitación en la celda %s" % celda)
		return

	if habitacion_actual:
		habitacion_actual.cerrar()
		remove_child(habitacion_actual)
		habitacion_actual.queue_free()

	celda_actual = celda
	habitacion_actual = ESCENA_HABITACION.instantiate() as Habitacion
	habitacion_actual.datos = celdas[celda]
	add_child(habitacion_actual)
	move_child(habitacion_actual, 0) # detrás del jugador
	habitacion_actual.preparar(celda, celdas[celda], vecinos_de(celda))
	habitacion_actual.puerta_cruzada.connect(_on_puerta_cruzada)
	jugador.position = posicion_jugador

	_actualizar_etiqueta()
	print("Habitación ", celda, " [", Catalogo.letra_categoria(categoria_de(celda)), "] -> ", describir_vecinos(celda))


func _on_puerta_cruzada(puerta: Puerta) -> void:
	var destino := celda_actual + Puerta.vector_de(puerta.direccion)
	var entrada := Puerta.opuesta(puerta.direccion)
	# Diferido: estamos dentro de una señal de física y no se pueden crear cuerpos ahora.
	cargar_habitacion.call_deferred(destino, posicion_de_entrada(entrada))


## Dónde aparece el jugador al entrar por la puerta "entrada" de la nueva habitación:
## justo dentro de la sala, sin tocar el hueco de la puerta (para no volver a cruzarla).
func posicion_de_entrada(entrada: Puerta.Direccion) -> Vector2:
	match entrada:
		Puerta.Direccion.NORTE:
			return Vector2(928, 192)
		Puerta.Direccion.ESTE:
			return Vector2(1248, 512)
		Puerta.Direccion.SUR:
			return Vector2(928, 832)
		_:
			return Vector2(608, 512)


func hay_habitacion(celda: Vector2i) -> bool:
	return celdas.has(celda)


func categoria_de(celda: Vector2i) -> int:
	return celdas[celda].categoria


## Devuelve {Puerta.Direccion: bool}: en qué direcciones hay habitación vecina.
func vecinos_de(celda: Vector2i) -> Dictionary:
	var vecinos := {}
	for dir in Puerta.Direccion.values():
		vecinos[dir] = hay_habitacion(celda + Puerta.vector_de(dir))
	return vecinos


func describir_vecinos(celda: Vector2i) -> String:
	var nombres := []
	var vecinos := vecinos_de(celda)
	for dir in vecinos:
		if vecinos[dir]:
			nombres.append(Puerta.Direccion.keys()[dir])
	return ", ".join(nombres)
	
func elegir_inicio() -> Vector2i:
	if celdas.is_empty():
		return Vector2i.ZERO

	var visitadas := {}
	var componentes: Array = []
	var tamano_max := 0

	for inicio in celdas.keys():
		if visitadas.has(inicio):
			continue
		var componente: Array = []
		var pendientes: Array = [inicio]
		visitadas[inicio] = true

		while not pendientes.is_empty():
			var actual: Vector2i = pendientes.pop_back()
			componente.append(actual)
			for dir in Puerta.Direccion.values():
				var vecino: Vector2i = actual + Puerta.vector_de(dir)
				if celdas.has(vecino) and not visitadas.has(vecino):
					visitadas[vecino] = true
					pendientes.append(vecino)

		if componente.size() > tamano_max:
			tamano_max = componente.size()
			componentes = [componente]
		elif componente.size() == tamano_max:
			componentes.append(componente)

	var mejor := Vector2i.ZERO
	var hay_mejor := false
	for componente in componentes:
		for celda in componente:
			var c: Vector2i = celda
			if not hay_mejor or _es_mejor_inicio(c, mejor):
				mejor = c
				hay_mejor = true
	return mejor


func _es_mejor_inicio(candidato: Vector2i, actual: Vector2i) -> bool:
	if candidato.y != actual.y:
		return candidato.y > actual.y

	var centro := Vector2((_columnas - 1) / 2.0, (_filas - 1) / 2.0)
	var d_candidato := Vector2(candidato).distance_squared_to(centro)
	var d_actual := Vector2(actual).distance_squared_to(centro)
	if not is_equal_approx(d_candidato, d_actual):
		return d_candidato < d_actual

	return candidato.x < actual.x

func _actualizar_etiqueta() -> void:
	var celda: CeldaTablero = celdas[celda_actual]
	var estado := " [resuelta]" if celda.resuelta else ""
	_etiqueta.text = "Sala %s [%s]%s" % [
		celda_actual,
		Catalogo.letra_categoria(celda.categoria),
		estado
	]

func sincronizar(matriz: Array) -> bool:
	generar(matriz)
	if celdas.is_empty():
		return false

	if habitacion_actual == null or not hay_habitacion(celda_actual):
		cargar_habitacion(elegir_inicio(), CENTRO_HABITACION)
	else:
		var estaba_resuelta:bool = habitacion_actual.datos != null and habitacion_actual.datos.resuelta

		habitacion_actual.preparar(
			celda_actual,
			celdas[celda_actual],
			vecinos_de(celda_actual)
		)

		if estaba_resuelta:
			celdas[celda_actual].resuelta = true

		_actualizar_etiqueta()
	return true
