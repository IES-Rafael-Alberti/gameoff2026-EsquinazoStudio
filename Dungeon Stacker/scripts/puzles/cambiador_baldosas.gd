class_name CambiadorBaldosas
extends TileMapLayer
## Alterna entre rocas y baldosas en las casillas que marcas, cuando se pisa una Placa.
##
## Este nodo ES la capa de marcas: pintas en él dos tipos de marca, "roca" y "baldosa". Al
## cargar la sala, bajo cada marca de roca se pone el tile de roca en el suelo y bajo cada
## marca de baldosa el de baldosa (solo donde el suelo tiene uno de los tiles de la lista
## "sobrescribibles", por ejemplo los tiles con la X roja). Cada vez que se pisa la placa, las
## rocas pasan a baldosas y las baldosas a rocas.
##
## Tiene que usar la misma cuadrícula que el suelo de la sala: mismo tamaño de celda y
## alineado con él. En el editor se ve; en juego se oculta y no colisiona ni navega.
##
## El estado se guarda en la celda de la sala (CeldaTablero.cambiadores_alternados): al volver
## a la sala las casillas siguen como se dejaron.
##
## Estructura: un TileMapLayer con este script, en la sala. La placa puede estar donde quieras
## en ella: se arrastran a "placas" en el inspector.

## Placas que lo activan: pisar cualquiera de ellas alterna. Conviene que no se queden
## activadas (se_queda_activa desmarcado) para poder pisarlas otra vez. No tienen por qué ser
## un desafío.
@export var placas: Array[Placa] = []

@export_group("Marcas (en esta capa)")
## Coordenadas en el atlas de la marca que significa "aquí empieza una roca".
var marca_roca := Vector2i(0, 0)
## Coordenadas en el atlas de la marca que significa "aquí empieza una baldosa".
var marca_baldosa := Vector2i(1, 0)

@export_group("Tiles del suelo")
## Coordenadas en el atlas del suelo del tile de roca.
@export var tile_roca := Vector2i(1, 3)
## Coordenadas en el atlas del suelo del tile de baldosa.
@export var tile_baldosa := Vector2i(0, 1)
## Tiles del suelo que el cambiador puede sobrescribir al cargar la sala bajo una marca. Si el
## tile que hay es otro (un muro, por ejemplo), esa casilla no se toca y no cambia nunca.
@export var sobrescribibles: Array[Vector2i] = [Vector2i(0, 1), Vector2i(2, 1), Vector2i(8, 1)]

var _habitacion: Habitacion
var _suelo: TileMapLayer
## Casillas del suelo (no de esta capa) que cambian.
var _celdas: Array[Vector2i] = []
var _alternado := false


func _ready() -> void:
	_habitacion = _buscar_habitacion()
	if _habitacion != null:
		_suelo = _habitacion.get_node_or_null("TileMapLayer") as TileMapLayer
	if _suelo == null or _suelo == self:
		push_warning("El cambiador %s necesita estar en una sala con un TileMapLayer de suelo." % name)
		return

	# Las marcas solo sirven para señalar casillas.
	visible = false
	collision_enabled = false
	navigation_enabled = false

	# Estado inicial: cada marca pone su tile en la casilla del suelo que queda en el mismo sitio.
	for celda in get_used_cells():
		var atlas := get_cell_atlas_coords(celda)
		var tile := Vector2i(-1, -1)
		if atlas == marca_roca:
			tile = tile_roca
		elif atlas == marca_baldosa:
			tile = tile_baldosa
		else:
			continue
		var global := to_global(map_to_local(celda))
		var casilla := _suelo.local_to_map(_suelo.to_local(global))
		var origen := _suelo.get_cell_source_id(casilla)
		if origen == -1 or not _suelo.get_cell_atlas_coords(casilla) in sobrescribibles:
			continue
		_suelo.set_cell(casilla, origen, tile, _suelo.get_cell_alternative_tile(casilla))
		_celdas.append(casilla)

	if placas.is_empty():
		push_warning("El cambiador %s no tiene ninguna placa asignada." % name)
	for placa in placas:
		if placa != null:
			placa.activada.connect(_alternar)

	# Se dejó alternado en una visita anterior: se vuelve a aplicar.
	if _habitacion.datos != null and _habitacion.datos.cambiadores_alternados.has(_clave()):
		_intercambiar()
		_alternado = true


func _alternar() -> void:
	_intercambiar()
	_alternado = not _alternado
	if _habitacion == null or _habitacion.datos == null:
		return
	var lista := _habitacion.datos.cambiadores_alternados
	if _alternado:
		if not lista.has(_clave()):
			lista.append(_clave())
	else:
		lista.erase(_clave())


## Las rocas pasan a baldosas y las baldosas a rocas en las casillas marcadas.
func _intercambiar() -> void:
	for celda in _celdas:
		var origen := _suelo.get_cell_source_id(celda)
		if origen == -1:
			continue
		var atlas := _suelo.get_cell_atlas_coords(celda)
		var alternativa := _suelo.get_cell_alternative_tile(celda)
		if atlas == tile_roca:
			_suelo.set_cell(celda, origen, tile_baldosa, alternativa)
		elif atlas == tile_baldosa:
			_suelo.set_cell(celda, origen, tile_roca, alternativa)


## Identifica este cambiador dentro de su sala: su ruta desde la sala. No sirve la posición
## porque las capas suelen estar todas en el origen.
func _clave() -> String:
	return str(_habitacion.get_path_to(self))


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
