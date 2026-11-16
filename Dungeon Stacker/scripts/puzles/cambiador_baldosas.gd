class_name CambiadorBaldosas
extends TileMapLayer
## Cambia baldosas de la sala cuando se pisa una Placa: en las casillas indicadas, las que
## tienen el tile A pasan a tener el B y las que tienen el B pasan a tener el A. Cada vez que
## se pisa la placa se alterna otra vez.
##
## Este nodo ES la capa de marcas: las casillas a cambiar se indican pintándolas en él (con
## cualquier tile, solo importa qué celdas están pintadas). Tiene que usar la misma cuadrícula
## que el suelo de la sala: mismo tamaño de celda y alineado con él. En el editor se ve; en
## juego se oculta y no colisiona ni navega.
##
## El estado se guarda en la celda de la sala (CeldaTablero.cambiadores_alternados): al volver
## a la sala las baldosas siguen como se dejaron.
##
## Estructura: un TileMapLayer con este script, en la sala. La placa puede estar donde quieras
## en ella: se arrastra a "placa" en el inspector.

## Placa que lo activa. Conviene que no se quede activada (se_queda_activa desmarcado) para
## poder pisarla otra vez. No tiene por qué ser un desafío.
@export var placa: Placa

@export_group("Tiles")
## Coordenadas en el atlas del tile A.
@export var tile_a := Vector2i(1, 3)
## Coordenadas en el atlas del tile B.
@export var tile_b := Vector2i(0, 1)

var _habitacion: Habitacion
var _suelo: TileMapLayer
## Casillas del suelo (no de Marcas) que se intercambian.
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

	# Se pasa cada casilla marcada a la casilla del suelo que queda en el mismo sitio.
	for celda in get_used_cells():
		var global := to_global(map_to_local(celda))
		_celdas.append(_suelo.local_to_map(_suelo.to_local(global)))

	if placa == null:
		push_warning("El cambiador %s no tiene placa asignada." % name)
	else:
		placa.activada.connect(_alternar)

	# Se dejó alternado en una visita anterior: se vuelve a aplicar.
	if _habitacion != null and _habitacion.datos != null and _habitacion.datos.cambiadores_alternados.has(_clave()):
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


## A pasa a B y B pasa a A en las casillas marcadas. El resto de casillas no se tocan.
func _intercambiar() -> void:
	for celda in _celdas:
		var origen := _suelo.get_cell_source_id(celda)
		if origen == -1:
			continue
		var atlas := _suelo.get_cell_atlas_coords(celda)
		var alternativa := _suelo.get_cell_alternative_tile(celda)
		if atlas == tile_a:
			_suelo.set_cell(celda, origen, tile_b, alternativa)
		elif atlas == tile_b:
			_suelo.set_cell(celda, origen, tile_a, alternativa)


## Identifica este cambiador dentro de su sala: su ruta desde la sala. No sirve la posición
## porque las capas suelen estar todas en el origen.
func _clave() -> String:
	return str(_habitacion.get_path_to(self))


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
