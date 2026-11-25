class_name CapaElectrica
extends TileMapLayer
## Red eléctrica de una sala. Este TileMapLayer ES la red: pintas en él los cables (apagados) y
## el script los enciende y apaga cambiando cada tile por su versión encendida.
##
## Cada tile de cable necesita dos datos en el TileSet (Custom Data Layers, con estos nombres):
##   conexiones (int): lados por los que el cable conecta, sumando N = 1, E = 2, S = 4, O = 8.
##                     Ej.: recta vertical = 5, esquina Norte-Este = 3, triple sin Sur = 11,
##                     cuádruple = 15. Cada giro (alternative tile) tiene sus propios datos.
##   encendido (Vector2i): coordenadas del atlas de la versión encendida de ese tile (en la
##                     misma fuente del atlas y con el mismo giro). (-1, -1) = no tiene.
## Pintas siempre la versión apagada.
##
## La corriente sale de las Fuentes y recorre los cables conectados: dos cables vecinos se unen
## si los dos tienen el lado que se mira. Un hueco en el cable se puentea con una PlacaInvisible
## (por ejemplo, una caja encima): pisada, la casilla conduce hacia sus cuatro vecinos.
##
## La luz recorre el cable casilla a casilla: cada casilla tarda "retardo_casilla" más que la
## anterior en encenderse. Al apagarse, las casillas más cercanas a lo que sigue con corriente se
## apagan primero y la oscuridad se aleja. Los receptores reaccionan cuando la luz llega a su
## casilla. Al cargar la sala, la red ya aparece encendida y los receptores no reaccionan (salvo
## los ObjetivoElectrico, que cuentan como alcanzados si ya les llega corriente).
## Si la sala ya estaba resuelta al cargarla, la red se ajusta al instante a las cajas que haya
## (sin recorrido de luz) y los receptores no reaccionan: láseres y cambiadores están como se
## guardaron.
##
## Estructura: un nodo (por ejemplo "Electricidad") que contiene esta capa y todo lo eléctrico de
## la sala. La capa detecta sola, entre todo lo que cuelga de su nodo padre (a cualquier
## profundidad y en cualquier orden):
##   - las FuenteElectrica,
##   - las PlacaInvisible, que hacen de puente,
##   - los nodos con el método recibir_corriente(hay: bool) (ReceptorElectrico, ObjetivoElectrico).
## Así basta con colocar los nodos dentro de ese padre, sin arrastrarlos a ninguna lista. Dentro de
## ese padre solo deben ir placas que sean puentes.

const DIRECCIONES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const BITS: Array[int] = [1, 2, 4, 8]
const DATO_CONEXIONES := "conexiones"
const DATO_ENCENDIDO := "encendido"
const SIN_VERSION := Vector2i(-1, -1)

## Segundos que tarda la luz en pasar de una casilla a la siguiente.
@export_range(0.0, 2.0, 0.01, "suffix:s") var retardo_casilla := 0.1

# Detectados al cargar entre los hijos del nodo padre.
var _fuentes: Array[FuenteElectrica] = []
var _puentes: Array[PlacaInvisible] = []
var _receptores: Array[Node2D] = []

# Casilla -> {conexiones, fuente (id del atlas), alt, apagado, encendido}
var _cables := {}
# Casillas que se ven encendidas ahora mismo.
var _encendidas := {}
# Casilla -> {tiempo, encender}: cambios que están esperando su turno.
var _pendientes := {}
# Casillas con puente activo.
var _puentes_activos := {}
# Casillas de las fuentes.
var _celdas_fuente: Array[Vector2i] = []
# Pasos desde la fuente de cada casilla con corriente, la última vez que se calculó.
var _distancias := {}
# La sala ya estaba resuelta cuando se cargó.
var _resuelta_al_cargar := false


func _ready() -> void:
	set_process(false)
	if tile_set == null or not tile_set.has_custom_data_layer_by_name(DATO_CONEXIONES) \
			or not tile_set.has_custom_data_layer_by_name(DATO_ENCENDIDO):
		push_error("%s: el TileSet necesita las capas de datos personalizados '%s' (int) y '%s' (Vector2i)." % [name, DATO_CONEXIONES, DATO_ENCENDIDO])
		return

	for celda in get_used_cells():
		var datos := get_cell_tile_data(celda)
		_cables[celda] = {
			"conexiones": int(datos.get_custom_data(DATO_CONEXIONES)),
			"fuente": get_cell_source_id(celda),
			"alt": get_cell_alternative_tile(celda),
			"apagado": get_cell_atlas_coords(celda),
			"encendido": datos.get_custom_data(DATO_ENCENDIDO) as Vector2i,
		}

	_descubrir()
	var sala := _buscar_habitacion()
	_resuelta_al_cargar = sala != null and sala.datos != null and sala.datos.resuelta

	for fuente in _fuentes:
		var celda := _celda_de(fuente)
		if not _cables.has(celda):
			push_warning("%s: la fuente %s no está sobre un cable (casilla %s)." % [name, fuente.name, celda])
			continue
		_celdas_fuente.append(celda)

	for puente in _puentes:
		puente.activada.connect(_on_puente.bind(puente, true))
		puente.desactivada.connect(_on_puente.bind(puente, false))

	_recalcular(true)


func _process(delta: float) -> void:
	for celda in _pendientes.keys():
		_pendientes[celda].tiempo -= delta
		if _pendientes[celda].tiempo <= 0.0:
			var encender: bool = _pendientes[celda].encender
			_pendientes.erase(celda)
			_aplicar_celda(celda, encender, true)
	if _pendientes.is_empty():
		set_process(false)


## Busca las fuentes, los puentes y los receptores entre todo lo que cuelga del nodo padre.
func _descubrir() -> void:
	var raiz := get_parent()
	if raiz == null or raiz is Habitacion:
		push_warning("%s: pon la capa dentro de un nodo que contenga todo lo eléctrico de la sala (por ejemplo 'Electricidad'), no directamente en la sala." % name)
		return
	for nodo in raiz.find_children("*", "", true, false):
		if nodo == self:
			continue
		if nodo is FuenteElectrica:
			_fuentes.append(nodo)
		elif nodo is PlacaInvisible:
			_puentes.append(nodo)
		elif nodo is Node2D and nodo.has_method("recibir_corriente"):
			_receptores.append(nodo)


func _on_puente(puente: PlacaInvisible, activo: bool) -> void:
	var celda := _celda_de(puente)
	if activo:
		_puentes_activos[celda] = true
	else:
		_puentes_activos.erase(celda)
	if _resuelta_al_cargar:
		_ajustar_al_instante()
	else:
		_recalcular(false)


## Al cargar, los receptores no reaccionan, pero los que tienen el método corriente_inicial
## (los ObjetivoElectrico) sí se enteran de si ya les llega corriente. Se avisa en diferido, cuando
## todos los nodos de la sala ya han terminado su _ready (por ejemplo, para registrarse como
## desafío). Si la sala ya estaba resuelta no hace falta: los objetivos aparecen resueltos solos.
func _avisar_corriente_inicial() -> void:
	if _resuelta_al_cargar:
		return
	for receptor in _receptores:
		if receptor.has_method("corriente_inicial"):
			receptor.corriente_inicial.call_deferred(_encendidas.has(_celda_de(receptor)))


## Sala resuelta cargada: pone cada casilla como le toca ya, sin recorrido ni avisos.
func _ajustar_al_instante() -> void:
	var objetivo := _alcanzar(_celdas_fuente)
	_pendientes.clear()
	for celda in _cables:
		_aplicar_celda(celda, objetivo.has(celda), false)
	_distancias = objetivo
	set_process(false)


## Calcula qué casillas deberían tener corriente y planifica lo que hay que encender o apagar.
func _recalcular(inicial: bool) -> void:
	var objetivo := _alcanzar(_celdas_fuente)

	if inicial:
		for celda in objetivo:
			if _cables.has(celda):
				_aplicar_celda(celda, true, false)
		_distancias = objetivo
		_avisar_corriente_inicial()
		return

	# Encender: pasos desde lo que ya está encendido (o las fuentes), solo por la parte nueva.
	var base: Array[Vector2i] = _celdas_fuente.duplicate()
	for celda in _encendidas:
		if objetivo.has(celda):
			base.append(celda)
	var desde_base := _alcanzar(base)

	var nuevos := {}
	for celda in objetivo:
		if _cables.has(celda) and not _encendidas.has(celda):
			nuevos[celda] = {"tiempo": desde_base.get(celda, 0) * retardo_casilla, "encender": true}

	# Apagar: las más cercanas a la fuente primero; la oscuridad se aleja.
	var a_apagar: Array[Vector2i] = []
	var minimo := 1000000
	for celda in _encendidas:
		if not objetivo.has(celda):
			a_apagar.append(celda)
			minimo = mini(minimo, _distancias.get(celda, 0))
	for celda in a_apagar:
		nuevos[celda] = {"tiempo": (_distancias.get(celda, 0) - minimo) * retardo_casilla, "encender": false}

	_distancias = objetivo
	_pendientes = nuevos
	set_process(not _pendientes.is_empty())


## Casillas con corriente y su distancia en pasos, a partir de unas casillas de origen.
func _alcanzar(origenes: Array[Vector2i]) -> Dictionary:
	var distancia := {}
	var cola: Array[Vector2i] = []
	for origen in origenes:
		if not distancia.has(origen):
			distancia[origen] = 0
			cola.append(origen)
	var i := 0
	while i < cola.size():
		var actual := cola[i]
		i += 1
		for vecina in _vecinas_conectadas(actual):
			if not distancia.has(vecina):
				distancia[vecina] = distancia[actual] + 1
				cola.append(vecina)
	return distancia


## Casillas a las que pasa la corriente desde una casilla: cables o puentes activos que se miran.
func _vecinas_conectadas(celda: Vector2i) -> Array[Vector2i]:
	var resultado: Array[Vector2i] = []
	var cable = _cables.get(celda)
	if cable == null and not _puentes_activos.has(celda):
		return resultado
	for lado in 4:
		# Un cable solo sale por sus lados abiertos; un puente conduce hacia los cuatro.
		if cable != null and not (cable.conexiones & BITS[lado]):
			continue
		var vecina := celda + DIRECCIONES[lado]
		var cable_vecino = _cables.get(vecina)
		if cable_vecino != null:
			if cable_vecino.conexiones & BITS[(lado + 2) % 4]:
				resultado.append(vecina)
		elif _puentes_activos.has(vecina):
			resultado.append(vecina)
	return resultado


## Pone una casilla encendida o apagada (cambia su tile) y avisa a los receptores que haya en ella.
func _aplicar_celda(celda: Vector2i, encender: bool, avisar: bool) -> void:
	var cable: Dictionary = _cables[celda]
	var atlas: Vector2i = cable.apagado
	if encender and cable.encendido != SIN_VERSION:
		atlas = cable.encendido
	set_cell(celda, cable.fuente, atlas, cable.alt)
	if encender:
		_encendidas[celda] = true
	else:
		_encendidas.erase(celda)
	if not avisar:
		return
	for receptor in _receptores:
		if _celda_de(receptor) == celda:
			receptor.recibir_corriente(encender)


func _celda_de(nodo: Node2D) -> Vector2i:
	return local_to_map(to_local(nodo.global_position))


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
