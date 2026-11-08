class_name Habitacion
extends Node2D

signal jugador_entro
signal puertas_cerradas
signal puertas_abiertas
signal desafios_resueltos
## El jugador ha cruzado una puerta abierta (puerta.direccion dice cuál).
signal puerta_cruzada(puerta: Puerta)

## Qué puertas tienen habitación al otro lado (solo para probar la escena suelta).
## Cuando la crea la Mazmorra, preparar() lo sobrescribe.
@export_flags("Norte", "Este", "Sur", "Oeste") var conexiones_iniciales := 15

## Datos que le asigna la mazmorra (a partir de su celda del tablero).
var posicion_tablero := Vector2i.ZERO
var categoria: int = Catalogo.Categoria.A
var bioma: int = Catalogo.Bioma.MEDIEVAL

var _puertas := {} # Puerta.Direccion -> Puerta
var _desafios: Array[Node] = []
var _jugador_dentro := false
var _puertas_cerradas := false
var datos: CeldaTablero
var _cerrando := false
var _tuvo_desafios := false
@onready var _zona: Area2D = $ZonaEntrada


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


## Lo llama la mazmorra justo después de añadir la habitación a la escena.
func preparar(posicion: Vector2i, celda: CeldaTablero, vecinos: Dictionary) -> void:
	datos = celda
	posicion_tablero = posicion
	categoria = celda.categoria
	bioma = celda.bioma
	configurar_conexiones(vecinos)


## vecinos: {Puerta.Direccion: bool}. Las direcciones que falten quedan selladas.
func configurar_conexiones(vecinos: Dictionary) -> void:
	for dir in _puertas:
		_puertas[dir].establecer_conectada(vecinos.get(dir, false))


## Anota un combate o puzzle. Se resuelve solo cuando el nodo sale del árbol
## (por ejemplo un enemigo que muere con queue_free).
func registrar_desafio(desafio: Node) -> void:
	if desafio in _desafios:
		return
	_desafios.append(desafio)
	_tuvo_desafios = true
	desafio.tree_exited.connect(resolver_desafio.bind(desafio), CONNECT_ONE_SHOT)
	_actualizar_puertas()

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


func _on_cuerpo_salio(cuerpo: Node2D) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	_jugador_dentro = false
	_actualizar_puertas()


## Las puertas se cierran solo si el jugador está dentro Y queda algo por resolver.
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
