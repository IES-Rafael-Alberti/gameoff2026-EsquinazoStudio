class_name Habitacion
extends Node2D

signal jugador_entro
signal puertas_cerradas
signal puertas_abiertas
signal desafios_resueltos
## El jugador ha cruzado una puerta abierta.
signal puerta_cruzada(puerta: Puerta)

@export_flags("Norte", "Este", "Sur", "Oeste") var conexiones_iniciales := 15
@export var dano_vacio := 1

var posicion_tablero := Vector2i.ZERO
var categoria: CategoriaSala
var bioma: int = Catalogo.Bioma.MEDIEVAL

var _puertas := {}
var _desafios: Array[Node] = []
var _jugador_dentro := false
var _puertas_cerradas := false
var datos: CeldaTablero
var _cerrando := false
var _tuvo_desafios := false
var _baldosas_rotas := {}
var llave_recogida_pos := Vector2i.ZERO
var _baldosas := {}

## Puerta por la que se entró en la sala o -1.
var entrada := -1
var _cayendo := false

@onready var _zona: Area2D = $ZonaEntrada
@onready var _tiles: TileMapLayer = $TileMapLayer


func _ready() -> void:
	for hijo in $Puertas.get_children():
		var puerta := hijo as Puerta
		if puerta:
			_puertas[puerta.direccion] = puerta
			puerta.jugador_cruzo.connect(puerta_cruzada.emit)

	var vecinos := {}
	for dir in Puerta.Direccion.values():
		vecinos[dir] = (conexiones_iniciales & (1 << dir)) != 0
	configurar_conexiones(vecinos)
	_zona.body_entered.connect(_on_cuerpo_entro)
	_zona.body_exited.connect(_on_cuerpo_salio)
	for nodo in get_tree().get_nodes_in_group("baldosa_rota"):
		var baldosa := nodo as BaldosaRota
		if baldosa != null and is_ancestor_of(baldosa):
			baldosa.rota.connect(_on_baldosa_rota)
			var celda := _tiles.local_to_map(_tiles.to_local(baldosa.global_position))
			_baldosas[celda] = baldosa

## Lo llama la mazmorra justo después de añadir la habitación a la escena.
func preparar(posicion: Vector2i, celda: CeldaTablero, vecinos: Dictionary, puerta_entrada := -1) -> void:
	datos = celda
	posicion_tablero = posicion
	categoria = celda.categoria
	bioma = celda.bioma
	entrada = puerta_entrada
	configurar_conexiones(vecinos)

## Las direcciones que falten quedan selladas.
func configurar_conexiones(vecinos: Dictionary) -> void:
	for dir in _puertas:
		_puertas[dir].establecer_conectada(vecinos.get(dir, false))


## Anota un combate o puzzle. Se resuelve cuando el nodo sale del árbol.
func registrar_desafio(desafio: Node) -> void:
	if desafio in _desafios:
		return
	_desafios.append(desafio)
	_tuvo_desafios = true
	desafio.tree_exited.connect(resolver_desafio.bind(desafio), CONNECT_ONE_SHOT)
	_actualizar_puertas()

## True mientras quede algún combate o puzzle sin resolver.
func tiene_desafios_pendientes() -> bool:
	return not _desafios.is_empty()

## Devuelve los puzles sin resolver y sus cajas a su estado inicial.
func reiniciar_puzles() -> void:
	_reiniciar_elementos()

func registrar_llave_recogida(pos: Vector2i) -> void:
	llave_recogida_pos = pos
	if datos != null and not datos.llaves_recogidas.has(pos):
		datos.llaves_recogidas.append(pos)


func registrar_cerradura_abierta(pos: Vector2i) -> void:
	if datos != null and not datos.cerraduras_abiertas.has(pos):
		datos.cerraduras_abiertas.append(pos)

func registrar_curacion_recogida(pos: Vector2i) -> void:
	if datos != null and not datos.curaciones_recogidas.has(pos):
		datos.curaciones_recogidas.append(pos)

func devolver_llave_al_salir(jugador) -> void:
	if jugador == null:
		return
	if jugador.tiene_llave and llave_recogida_pos != Vector2i.ZERO and datos != null:
		datos.llaves_recogidas.erase(llave_recogida_pos)
	if jugador.has_method("perder_llave"):
		jugador.perder_llave()
	llave_recogida_pos = Vector2i.ZERO

func _reiniciar_elementos() -> void:
	_restaurar_baldosas()
	for nodo in get_tree().get_nodes_in_group("caja") + get_tree().get_nodes_in_group("desafio"):
		if is_ancestor_of(nodo):
			nodo.reiniciar()

func _restaurar_baldosas() -> void:
	for baldosa in _baldosas_rotas.values():
		if is_instance_valid(baldosa):
			baldosa.restaurar()
	_baldosas_rotas.clear()

func _comprobar_cajas() -> void:
	for nodo in get_tree().get_nodes_in_group("caja"):
		var caja := nodo as Caja
		if caja == null:
			continue
		if not is_instance_valid(caja) or not is_ancestor_of(caja):
			continue
		if caja.cayendo or caja._moviendo or caja.reiniciando:
			continue
		var celda := _tiles.local_to_map(_tiles.to_local(caja.global_position))
		if _es_hueco_para_caja(celda):
			_caja_cae(caja)

func _caja_cae(caja: Caja) -> void:
	await caja.caer_al_vacio()

## La caja se hunde solo en el vacío que ninguna baldosa tapa.
func _es_hueco_para_caja(celda: Vector2i) -> bool:
	if _baldosas_rotas.has(celda):
		return true
	if _baldosas.has(celda):
		return false
	var tile := _tiles.get_cell_tile_data(celda)
	return tile != null and tile.get_custom_data("vacio")

func resolver_desafio(desafio: Node) -> void:
	if not _desafios.has(desafio):
		return
	_desafios.erase(desafio)
	_actualizar_puertas()
	if _cerrando or not _desafios.is_empty():
		return
	if _tuvo_desafios and datos != null:
		datos.resuelta = true
		desafios_resueltos.emit()

func _on_cuerpo_entro(cuerpo: Node2D) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	_jugador_dentro = true
	jugador_entro.emit()
	_actualizar_puertas()
	_resolver_si_corresponde()

func _on_cuerpo_salio(cuerpo: Node2D) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	_jugador_dentro = false
	_actualizar_puertas()

## Las puertas se cierran solo si el jugador está dentro y queda algo por resolver.
func _actualizar_puertas() -> void:
	var debe_cerrar := _jugador_dentro and not _desafios.is_empty()
	if debe_cerrar == _puertas_cerradas:
		return
	_puertas_cerradas = debe_cerrar
	for puerta in _puertas.values():
		if debe_cerrar:
			puerta.cerrar()
		else:
			puerta.abrir()
	if debe_cerrar:
		puertas_cerradas.emit()
	else:
		puertas_abiertas.emit()

func cerrar() -> void:
	_cerrando = true

## Las salas marcadas como "se resuelve al entrar" se completan al pisarlas.
func _resolver_si_corresponde() -> void:
	if datos == null or datos.resuelta:
		return
	if categoria == null or not categoria.se_resuelve_al_entrar:
		return
	if not _desafios.is_empty():
		return
	datos.resuelta = true
	desafios_resueltos.emit()

## Dónde debe quedar el centro del cuerpo del jugador al entrar por esa puerta.
func punto_de_entrada(entrada: int) -> Vector2:
	var nombre := ""
	match entrada:
		Puerta.Direccion.NORTE:
			nombre = "EntradaNorte"
		Puerta.Direccion.ESTE:
			nombre = "EntradaEste"
		Puerta.Direccion.SUR:
			nombre = "EntradaSur"
		Puerta.Direccion.OESTE:
			nombre = "EntradaOeste"
	var marcador := get_node_or_null("Entradas/" + nombre) as Marker2D
	if marcador == null:
		push_warning("La sala %s no tiene el marcador Entradas/%s" % [name, nombre])
		return Mazmorra.CENTRO_HABITACION
	return marcador.global_position

func _physics_process(_delta: float) -> void:
	if datos == null:
		return
	_comprobar_cajas()
	if _cayendo:
		return
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null or not jugador.vida.esta_viva():
		return
	var celda := _tiles.local_to_map(_tiles.to_local(jugador.centro()))
	if _es_vacio(celda):
		_caer(jugador)

func _es_vacio(celda: Vector2i) -> bool:
	if _baldosas_rotas.has(celda):
		return true
	if _baldosas.has(celda):
		return false
	var tile := _tiles.get_cell_tile_data(celda)
	return tile != null and tile.get_custom_data("vacio")

func _caer(jugador) -> void:
	_cayendo = true
	var destino_centro := punto_de_entrada(entrada) if entrada >= 0 else Mazmorra.CENTRO_HABITACION
	await jugador.caer_al_vacio(dano_vacio, destino_centro - jugador.desfase_centro())
	_cayendo = false
	if not is_inside_tree():
		return
	_restaurar_baldosas()

func _on_baldosa_rota(baldosa: BaldosaRota) -> void:
	var celda := _tiles.local_to_map(_tiles.to_local(baldosa.global_position))
	_baldosas_rotas[celda] = baldosa
