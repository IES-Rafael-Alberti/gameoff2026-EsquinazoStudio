class_name Mazmorra
extends Node2D

const ESCENA_HABITACION := preload("res://scenes/Habitacion_Base.tscn")
## Centro de la habitación, en coordenadas de la propia habitación.
const CENTRO_HABITACION := Vector2(928, 512)

## Habitaciones de la mazmorra: Vector2i(x, y) -> CeldaTablero (categoría y bioma).
## La forma de la mazmorra es la forma que dejan las piezas en el tablero.
var celdas := {}

var celda_actual := Vector2i.ZERO
var habitacion_actual: Habitacion

@onready var jugador: CharacterBody2D = $Jugador


func _ready() -> void:
	# Diseño de prueba: 0 = vacío, 1..6 = categoría A..F.
	# Más adelante se sustituye por tablero.matriz (null = vacío).
	var diseno := [
		[0, 2, 0],
		[1, 3, 4],
		[0, 5, 0],
	]

	var matriz: Array = []
	for fila in diseno:
		var fila_matriz: Array = []
		for valor in fila:
			if valor == 0:
				fila_matriz.append(null)
			else:
				fila_matriz.append(CeldaTablero.new(null, valor - 1))
		matriz.append(fila_matriz)

	generar(matriz)
	cargar_habitacion(Vector2i(1, 0))


## Lee una matriz como la de tablero.matriz: null = sin habitación, CeldaTablero = habitación.
func generar(matriz: Array) -> void:
	celdas.clear()
	for y in matriz.size():
		for x in matriz[y].size():
			if matriz[y][x] != null:
				celdas[Vector2i(x, y)] = matriz[y][x]


## Sustituye la habitación cargada por la de esta celda y coloca al jugador.
func cargar_habitacion(celda: Vector2i, posicion_jugador: Vector2 = CENTRO_HABITACION) -> void:
	if not hay_habitacion(celda):
		push_warning("No hay habitación en la celda %s" % celda)
		return

	if habitacion_actual:
		remove_child(habitacion_actual)
		habitacion_actual.queue_free()

	celda_actual = celda
	habitacion_actual = ESCENA_HABITACION.instantiate() as Habitacion
	add_child(habitacion_actual)
	move_child(habitacion_actual, 0) # detrás del jugador
	habitacion_actual.preparar(celda, celdas[celda], vecinos_de(celda))
	habitacion_actual.puerta_cruzada.connect(_on_puerta_cruzada)
	jugador.position = posicion_jugador

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
