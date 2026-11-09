class_name Mazmorra
extends Node2D

enum Lugar { NINGUNO, VESTIBULO_INFERIOR, VESTIBULO_SUPERIOR, SALA }

## Sala base: se usa cuando no hay ninguna sala en el pool que toca.
const ESCENA_HABITACION := preload("res://scenes/Habitacion_Base.tscn")
## Centro de la habitación, en coordenadas de la propia habitación.
const CENTRO_HABITACION := Vector2(928, 512)

## Pools de salas por bioma y categoría. Lo asigna Juego desde la configuración del nivel.
var contenido: ContenidoSalas

## Habitaciones de la mazmorra: Vector2i(x, y) -> CeldaTablero (categoría y bioma).
## La forma de la mazmorra es la forma que dejan las piezas en el tablero.
var celdas := {}
var _columnas := 0
var _filas := 0
var lugar := Lugar.NINGUNO
var celda_actual := Vector2i.ZERO
var habitacion_actual: Habitacion

var _activa := false
var _vestibulo_inferior: Vestibulo
var _vestibulo_superior: Vestibulo
var _camara: Camera2D # solo activa dentro de un vestíbulo
var _etiqueta: Label # provisional: muestra en qué sala estás

@onready var jugador: CharacterBody2D = $Jugador


func _ready() -> void:
	_crear_etiqueta()
	_etiqueta.visible = false
	_camara = Camera2D.new()
	_camara.enabled = false
	add_child(_camara)


func _process(_delta: float) -> void:
	if _camara.enabled:
		_seguir_jugador()


func _notification(what: int) -> void:
	# Los vestíbulos que están fuera del árbol no los libera nadie más.
	if what == NOTIFICATION_PREDELETE:
		for vestibulo in [_vestibulo_inferior, _vestibulo_superior]:
			if is_instance_valid(vestibulo) and vestibulo.get_parent() == null:
				vestibulo.free()


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
	_activa = activa
	if _etiqueta != null:
		_etiqueta.visible = activa
	_actualizar_camara()


## La cámara solo se usa en los vestíbulos (son más anchos que la pantalla) y solo en
## modo mazmorra; en las salas y en el tetris se desactiva y la vista queda como siempre.
func _actualizar_camara() -> void:
	if _camara == null:
		return
	var en_vestibulo := lugar == Lugar.VESTIBULO_INFERIOR or lugar == Lugar.VESTIBULO_SUPERIOR
	_camara.enabled = _activa and en_vestibulo
	if _camara.enabled:
		_seguir_jugador()
		_camara.make_current()


## Sigue al jugador en horizontal sin salirse de los extremos del vestíbulo.
## En vertical queda fija, a la altura del centro de la pantalla.
func _seguir_jugador() -> void:
	var vestibulo := _vestibulo_inferior if lugar == Lugar.VESTIBULO_INFERIOR else _vestibulo_superior
	var vista := get_viewport_rect().size
	var izquierda := vestibulo.global_position.x
	var derecha := izquierda + vestibulo.ancho_total()
	var x := jugador.global_position.x
	if derecha - izquierda <= vista.x:
		x = (izquierda + derecha) / 2.0
	else:
		x = clampf(x, izquierda + vista.x / 2.0, derecha - vista.x / 2.0)
	_camara.global_position = Vector2(x, vista.y / 2.0)


## Lee una matriz como la de tablero.matriz: null = sin habitación, CeldaTablero = habitación.
func generar(matriz: Array) -> void:
	celdas.clear()
	_filas = matriz.size()
	_columnas = 0 if _filas == 0 else matriz[0].size()
	for y in _filas:
		for x in matriz[y].size():
			if matriz[y][x] != null:
				celdas[Vector2i(x, y)] = matriz[y][x]
	_asegurar_vestibulos()


## Crea los vestíbulos la primera vez que se conoce el número de columnas.
func _asegurar_vestibulos() -> void:
	if _vestibulo_inferior != null or _columnas == 0:
		return
	_vestibulo_inferior = _crear_vestibulo(Vestibulo.Tipo.INFERIOR)
	_vestibulo_superior = _crear_vestibulo(Vestibulo.Tipo.SUPERIOR)


## Lo construye pero lo deja FUERA del árbol: solo entra cuando el jugador está en él.
func _crear_vestibulo(tipo: Vestibulo.Tipo) -> Vestibulo:
	var vestibulo := Vestibulo.new()
	vestibulo.tipo = tipo
	vestibulo.construir(_columnas)
	# Centrado respecto a la sala. El superior está volteado: crece hacia arriba desde su origen.
	var x := CENTRO_HABITACION.x - vestibulo.ancho_total() / 2.0
	var mitad_alto := vestibulo.alto_total() / 2.0
	var y := CENTRO_HABITACION.y - mitad_alto if tipo == Vestibulo.Tipo.INFERIOR else CENTRO_HABITACION.y + mitad_alto
	vestibulo.position = Vector2(x, y)
	vestibulo.puerta_cruzada.connect(_on_vestibulo_cruzado.bind(tipo))
	return vestibulo


## Una puerta del vestíbulo se abre si hay sala en el tablero justo en esa columna.
func _actualizar_puertas_vestibulos() -> void:
	for x in _columnas:
		_vestibulo_inferior.establecer_puerta(x, hay_habitacion(Vector2i(x, _filas - 1)))
		_vestibulo_superior.establecer_puerta(x, hay_habitacion(Vector2i(x, 0)))


## Un vestíbulo inactivo no está en el árbol, así que no puede colisionar con nada.
func _mostrar_vestibulo(vestibulo: Vestibulo, activo: bool) -> void:
	if activo and vestibulo.get_parent() == null:
		add_child(vestibulo)
		move_child(vestibulo, 0) # detrás del jugador
	elif not activo and vestibulo.get_parent() != null:
		remove_child(vestibulo)


func _descargar_habitacion() -> void:
	if habitacion_actual == null:
		return
	habitacion_actual.cerrar()
	remove_child(habitacion_actual)
	habitacion_actual.queue_free()
	habitacion_actual = null


## Crea la sala de una celda con la variante que le toca (la elige del pool la primera vez).
func _instanciar_sala(datos_celda: CeldaTablero) -> Habitacion:
	if datos_celda.escena_sala == null:
		datos_celda.escena_sala = _elegir_escena(datos_celda)
	var sala := datos_celda.escena_sala.instantiate() as Habitacion
	if sala == null:
		push_error("La escena elegida no tiene el script Habitacion; usando la sala base.")
		datos_celda.escena_sala = ESCENA_HABITACION
		sala = ESCENA_HABITACION.instantiate() as Habitacion
	return sala


func _elegir_escena(datos_celda: CeldaTablero) -> PackedScene:
	var escena: PackedScene = null
	if contenido != null:
		escena = contenido.elegir(datos_celda.bioma, datos_celda.categoria)
	if escena == null:
		var nombre := "sin categoría" if datos_celda.categoria == null else datos_celda.categoria.nombre
		push_warning("Sin salas en el pool %s / %s; usando la sala base." % [
			Catalogo.NOMBRES_BIOMA.get(datos_celda.bioma, "?"), nombre
		])
		escena = ESCENA_HABITACION
	return escena


## Sustituye la habitación cargada por la de esta celda y coloca al jugador.
func cargar_habitacion(celda: Vector2i, posicion_jugador: Vector2 = CENTRO_HABITACION) -> void:
	if not hay_habitacion(celda):
		push_warning("No hay habitación en la celda %s" % celda)
		return

	_descargar_habitacion()
	_mostrar_vestibulo(_vestibulo_inferior, false)
	_mostrar_vestibulo(_vestibulo_superior, false)

	lugar = Lugar.SALA
	celda_actual = celda
	var datos_celda: CeldaTablero = celdas[celda]
	habitacion_actual = _instanciar_sala(datos_celda)
	habitacion_actual.datos = datos_celda
	add_child(habitacion_actual)
	move_child(habitacion_actual, 0) # detrás del jugador
	habitacion_actual.preparar(celda, datos_celda, vecinos_de(celda))
	habitacion_actual.puerta_cruzada.connect(_on_puerta_cruzada)
	jugador.position = posicion_jugador

	_actualizar_camara()
	_actualizar_etiqueta()
	print("Habitación ", celda, " [", _letra_de(datos_celda.categoria), "] -> ", describir_vecinos(celda))


## Pasa a un vestíbulo. columna >= 0: delante de su puerta; columna < 0: en la zona de spawn.
func _entrar_vestibulo(donde: Lugar, columna: int) -> void:
	_descargar_habitacion()
	lugar = donde
	_mostrar_vestibulo(_vestibulo_inferior, donde == Lugar.VESTIBULO_INFERIOR)
	_mostrar_vestibulo(_vestibulo_superior, donde == Lugar.VESTIBULO_SUPERIOR)
	var vestibulo := _vestibulo_inferior if donde == Lugar.VESTIBULO_INFERIOR else _vestibulo_superior
	if columna < 0:
		jugador.global_position = vestibulo.posicion_spawn()
	else:
		jugador.global_position = vestibulo.posicion_entrada(columna)
	_actualizar_camara()
	_actualizar_etiqueta()
	print("Vestíbulo ", Lugar.keys()[donde], " columna ", columna)


func _on_puerta_cruzada(puerta: Puerta) -> void:
	var destino := celda_actual + Puerta.vector_de(puerta.direccion)
	# Diferido: estamos dentro de una señal de física y no se pueden crear cuerpos ahora.
	if destino.y >= _filas:
		_entrar_vestibulo.call_deferred(Lugar.VESTIBULO_INFERIOR, destino.x)
	elif destino.y < 0:
		_entrar_vestibulo.call_deferred(Lugar.VESTIBULO_SUPERIOR, destino.x)
	else:
		var entrada := Puerta.opuesta(puerta.direccion)
		cargar_habitacion.call_deferred(destino, posicion_de_entrada(entrada))


func _on_vestibulo_cruzado(columna: int, tipo: Vestibulo.Tipo) -> void:
	if tipo == Vestibulo.Tipo.INFERIOR:
		# Subes desde abajo: entras por la puerta SUR de la sala.
		cargar_habitacion.call_deferred(Vector2i(columna, _filas - 1), posicion_de_entrada(Puerta.Direccion.SUR))
	else:
		cargar_habitacion.call_deferred(Vector2i(columna, 0), posicion_de_entrada(Puerta.Direccion.NORTE))


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


## Hay algo al otro lado: una sala, o un vestíbulo (justo encima o debajo del tablero).
func hay_conexion(celda: Vector2i) -> bool:
	if hay_habitacion(celda):
		return true
	return celda.x >= 0 and celda.x < _columnas and (celda.y == -1 or celda.y == _filas)


func categoria_de(celda: Vector2i) -> CategoriaSala:
	return celdas[celda].categoria


## Devuelve {Puerta.Direccion: bool}: en qué direcciones hay algo conectado.
func vecinos_de(celda: Vector2i) -> Dictionary:
	var vecinos := {}
	for dir in Puerta.Direccion.values():
		vecinos[dir] = hay_conexion(celda + Puerta.vector_de(dir))
	return vecinos


func describir_vecinos(celda: Vector2i) -> String:
	var nombres := []
	var vecinos := vecinos_de(celda)
	for dir in vecinos:
		if vecinos[dir]:
			nombres.append(Puerta.Direccion.keys()[dir])
	return ", ".join(nombres)


func _letra_de(categoria: CategoriaSala) -> String:
	return "-" if categoria == null else categoria.letra


func _actualizar_etiqueta() -> void:
	match lugar:
		Lugar.VESTIBULO_INFERIOR:
			_etiqueta.text = "Vestíbulo inferior"
		Lugar.VESTIBULO_SUPERIOR:
			_etiqueta.text = "Vestíbulo superior"
		Lugar.SALA:
			var celda: CeldaTablero = celdas[celda_actual]
			var estado := " [resuelta]" if celda.resuelta else ""
			_etiqueta.text = "Sala %s [%s]%s" % [
				celda_actual,
				_letra_de(celda.categoria),
				estado
			]


## Se llama al pasar de tetris a mazmorra.
func sincronizar(matriz: Array) -> void:
	# Tu sala es una CeldaTablero concreta; si bajaron filas, su posición ha cambiado.
	var datos_actuales: CeldaTablero = null
	if lugar == Lugar.SALA and habitacion_actual != null:
		datos_actuales = habitacion_actual.datos

	generar(matriz)
	_actualizar_puertas_vestibulos()

	# Si estabas en un vestíbulo, sigues en él: solo cambian sus puertas.
	if lugar == Lugar.VESTIBULO_INFERIOR or lugar == Lugar.VESTIBULO_SUPERIOR:
		return

	var posicion_nueva := Vector2i(-1, -1)
	if datos_actuales != null:
		for posicion in celdas:
			if celdas[posicion] == datos_actuales:
				posicion_nueva = posicion
				break

	if posicion_nueva == Vector2i(-1, -1):
		# Primera vez, o tu casilla se borró: entras a la mazmorra de nuevo, en la zona de spawn.
		_entrar_vestibulo(Lugar.VESTIBULO_INFERIOR, -1)
	else:
		# Sigues en tu sala; solo se actualizan su posición y sus puertas.
		celda_actual = posicion_nueva
		habitacion_actual.preparar(celda_actual, datos_actuales, vecinos_de(celda_actual))
		_actualizar_etiqueta()
