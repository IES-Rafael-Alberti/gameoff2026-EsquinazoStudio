class_name Vestibulo
extends Node2D
## Sala con una puerta por columna del tablero.
## Se construye en un solo TileMapLayer copiando tiles de las escenas plantilla:
##   extremo | tramo | tramo | ... | tramo | extremo   + una zona (spawn/jefe) pegada abajo.
## INFERIOR: puertas al norte. SUPERIOR: lo mismo volteado en vertical (scale.y = -1),
## con las puertas al sur y la zona arriba.

signal puerta_cruzada(columna: int)
## El jugador ha tocado la puerta de salida del nivel (solo la del vestíbulo superior funciona).
signal nivel_completado

enum Tipo { INFERIOR, SUPERIOR }

const ESCENA_TRAMO := preload("res://scenes/mazmorra/vestibulo_tramo.tscn")
const ESCENA_EXTREMO := preload("res://scenes/mazmorra/vestibulo_extremo.tscn")
const ESCENA_PUERTA := preload("res://scenes/mazmorra/puerta.tscn")
const ESCENA_PUERTA_NIVEL := preload("res://scenes/mazmorra/puerta_nivel.tscn")
const ESCENA_ZONA_INFERIOR := preload("res://scenes/mazmorra/vestibulo_zona_inferior.tscn")
const ESCENA_ZONA_SUPERIOR := preload("res://scenes/mazmorra/vestibulo_zona_superior.tscn")

## true = el sprite de la puerta del nivel del vestíbulo superior sale reflejado en vertical,
## como el resto del vestíbulo; false = se ve derecho. No afecta a su zona de colisión.
const PUERTA_NIVEL_REFLEJADA := true

@export var tipo := Tipo.INFERIOR
## Dónde aparece el jugador respecto al centro de su puerta, hacia dentro del vestíbulo.
@export var desplazamiento_entrada := Vector2(0, 96)

var _capa: TileMapLayer
var _puertas: Array[Puerta] = []
var _tam_celda := 64
var _columnas_celdas := 0
var _filas_celdas := 0
var _celdas_puerta := {}
var _spawn_local := Vector2.ZERO
var _tiene_spawn := false


## Se llama una sola vez, con el número de columnas del tablero.
func construir(columnas: int) -> void:
	scale = Vector2(1, -1) if tipo == Tipo.SUPERIOR else Vector2.ONE

	var tramo := ESCENA_TRAMO.instantiate()
	var extremo := ESCENA_EXTREMO.instantiate()
	var capa_tramo := tramo.get_node("TileMapLayer") as TileMapLayer
	var capa_extremo := extremo.get_node("TileMapLayer") as TileMapLayer
	var puerta_plantilla := tramo.get_node("Puerta") as Node2D

	# Una sola capa para todo: sin tiles duplicados y con colisión coherente con lo que se ve.
	_capa = TileMapLayer.new()
	_capa.tile_set = capa_tramo.tile_set
	_capa.scale = capa_tramo.scale
	add_child(_capa)
	_tam_celda = int(_capa.tile_set.tile_size.x * _capa.scale.x)

	var tamano_tramo := capa_tramo.get_used_rect().size
	var ancho_extremo := capa_extremo.get_used_rect().size.x
	var puerta_en_tramo := puerta_plantilla.position - Vector2(capa_tramo.get_used_rect().position * _tam_celda)

	_estampar(capa_extremo, Vector2i.ZERO)
	var x := ancho_extremo
	for columna in columnas:
		_estampar(capa_tramo, Vector2i(x, 0))
		# La dirección de la puerta se queda en NORTE (la del tramo): en el vestíbulo superior
		# el volteo de todo el vestíbulo ya la deja mirando al otro lado.
		var puerta := ESCENA_PUERTA.instantiate() as Puerta
		puerta.position = puerta_en_tramo + Vector2(x * _tam_celda, 0)
		puerta.jugador_cruzo.connect(_on_jugador_cruzo.bind(columna))
		add_child(puerta)
		_puertas.append(puerta)
		_celdas_puerta[Vector2i((puerta.position / _tam_celda).floor())] = true
		x += tamano_tramo.x
	_estampar(capa_extremo, Vector2i(x, 0), true) # cierra la pared del final

	_columnas_celdas = x + ancho_extremo
	_filas_celdas = tamano_tramo.y
	tramo.free()
	extremo.free()

	_construir_zona()
	_comprobar_cerrado()


## true = hay sala al otro lado y la puerta se abre; false = queda cerrada.
func establecer_puerta(columna: int, abierta: bool) -> void:
	if columna >= 0 and columna < _puertas.size():
		_puertas[columna].establecer_conectada(abierta)


## Tamaño en píxeles.
func ancho_total() -> float:
	return _columnas_celdas * _tam_celda


func alto_total() -> float:
	return _filas_celdas * _tam_celda


## Posición global donde colocar al jugador cuando entra por la puerta de esta columna.
func posicion_entrada(columna: int) -> Vector2:
	return to_global(_puertas[columna].position + desplazamiento_entrada)


## Posición global del hueco de spawn de la zona; si no hay, delante de la puerta central.
func posicion_spawn() -> Vector2:
	if _tiene_spawn:
		return to_global(_spawn_local)
	return posicion_entrada(_puertas.size() / 2)


## Copia los tiles pintados de una plantilla en la capa, a partir de una celda destino.
func _estampar(origen: TileMapLayer, destino: Vector2i, flip_h := false) -> void:
	var rect := origen.get_used_rect()
	for celda in origen.get_used_cells():
		var posicion := celda - rect.position
		if flip_h:
			posicion.x = rect.size.x - 1 - posicion.x
		var atlas := origen.get_cell_atlas_coords(celda)
		var source_id := origen.get_cell_source_id(celda)
		var alternativa := origen.get_cell_alternative_tile(celda)
		if flip_h:
			alternativa = alternativa ^ TileSetAtlasSource.TRANSFORM_FLIP_H
		_capa.set_cell(destino + posicion, source_id, atlas, alternativa)


## Pega la zona centrada, con su primera fila sobre la última fila del vestíbulo (la pared).
## Solo sobrescribe las celdas que la zona tiene pintadas: lo demás sigue siendo pared.
func _construir_zona() -> void:
	var escena := ESCENA_ZONA_INFERIOR if tipo == Tipo.INFERIOR else ESCENA_ZONA_SUPERIOR
	var zona := escena.instantiate()
	var capa := zona.get_node("TileMapLayer") as TileMapLayer
	var rect := capa.get_used_rect()

	# Con 2 columnas la zona ocupa todo el ancho del vestíbulo y sus esquinas de la
	# primera fila caen encima de los muros de los extremos. Las sustituimos por el
	# muro que tienen justo debajo. En el superior, como se pega en espejo, esa misma
	# celda es la que se ve arriba: no hay que buscar la última fila de la plantilla.
	if rect.size.x >= _columnas_celdas:
		var fila := rect.position.y
		for x in [rect.position.x, rect.position.x + rect.size.x - 1]:
			var destino := Vector2i(x, fila)
			var muro := Vector2i(x, fila + 1)
			if capa.get_cell_source_id(muro) == -1:
				continue
			capa.set_cell(destino,
				capa.get_cell_source_id(muro),
				capa.get_cell_atlas_coords(muro),
				capa.get_cell_alternative_tile(muro))

	var origen := Vector2i(int((_columnas_celdas - rect.size.x) / 2.0), _filas_celdas - 1)
	_estampar(capa, origen)

	var marcador := zona.get_node_or_null("Spawn") as Node2D
	if marcador != null:
		_spawn_local = Vector2(origen * _tam_celda) + marcador.position - Vector2(rect.position * _tam_celda)
		_tiene_spawn = true

	# Puerta del nivel: donde la zona tenga un marcador "PuertaNivel". En las dos zonas se pone,
	# pero solo funciona la del vestíbulo superior (la salida del nivel).
	var marcador_puerta := zona.get_node_or_null("PuertaNivel") as Node2D
	if marcador_puerta != null:
		var puerta_nivel := ESCENA_PUERTA_NIVEL.instantiate() as PuertaNivel
		puerta_nivel.position = Vector2(origen * _tam_celda) + marcador_puerta.position - Vector2(rect.position * _tam_celda)
		puerta_nivel.activa = tipo == Tipo.SUPERIOR
		puerta_nivel.establecer_abierta(tipo == Tipo.SUPERIOR)
		# El vestíbulo superior está volteado: se compensa en la puerta entera (así su zona de
		# colisión queda dentro del vestíbulo) y, si se quiere reflejada, se voltean solo los sprites.
		if tipo == Tipo.SUPERIOR:
			puerta_nivel.scale.y = -1.0
			if PUERTA_NIVEL_REFLEJADA:
				puerta_nivel.reflejar_sprites()
		puerta_nivel.tocada.connect(_on_puerta_nivel_tocada)
		add_child(puerta_nivel)
	elif tipo == Tipo.SUPERIOR:
		push_warning("Vestibulo: la zona superior no tiene un marcador \"PuertaNivel\": no hay salida de nivel.")
	_filas_celdas = origen.y + rect.size.y
	zona.free()


## Rellena desde el suelo (justo debajo de la primera puerta) por todas las celdas sin colisión.
## Si llega a una celda sin tile, hay un hueco en la pared: lo avisa en la consola.
## Las puertas cuentan como pared, porque el hueco de la puerta es una salida a propósito.
func _comprobar_cerrado() -> void:
	var inicio := Vector2i((_puertas[0].position / _tam_celda).floor()) + Vector2i.DOWN
	var visitadas := {inicio: true}
	var pendientes: Array[Vector2i] = [inicio]
	while not pendientes.is_empty():
		var actual: Vector2i = pendientes.pop_back()
		for desplazamiento in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var vecina: Vector2i = actual + desplazamiento
			if visitadas.has(vecina) or _celdas_puerta.has(vecina):
				continue
			if _capa.get_cell_source_id(vecina) == -1:
				push_warning("Vestíbulo %s con pared abierta: la celda %s no tiene tile (junto a %s)" % [
					Tipo.keys()[tipo], vecina, actual
				])
				return
			var datos := _capa.get_cell_tile_data(vecina)
			var es_solida := datos != null and datos.get_collision_polygons_count(0) > 0
			if not es_solida:
				visitadas[vecina] = true
				pendientes.append(vecina)

func _on_puerta_nivel_tocada() -> void:
	nivel_completado.emit()

func _on_jugador_cruzo(_puerta: Puerta, columna: int) -> void:
	puerta_cruzada.emit(columna)

## Columna de la puerta más cercana horizontalmente a esta posición global.
func columna_cercana(posicion_global: Vector2) -> int:
	if _puertas.is_empty():
		return -1
	var x := to_local(posicion_global).x
	var mejor := 0
	var mejor_distancia := INF
	for i in _puertas.size():
		var distancia := absf(_puertas[i].position.x - x)
		if distancia < mejor_distancia:
			mejor_distancia = distancia
			mejor = i
	return mejor
