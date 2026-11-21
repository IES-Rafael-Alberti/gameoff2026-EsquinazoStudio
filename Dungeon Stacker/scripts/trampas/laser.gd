class_name Laser
extends Peligro
## Láser: una barrera con dos emisores y un haz entre ellos, hecho repitiendo una pieza central.
## Encendido, el haz daña y bloquea el paso; apagado, se puede cruzar por el hueco. Los emisores
## bloquean siempre.
##
## Se enciende y apaga con placas (pisar cualquiera alterna) o desde fuera con encender(),
## apagar() y alternar(): la electricidad que haremos luego llamará a estos métodos o escuchará
## la señal estado_cambiado. Para girarlo, rota el nodo (rotation = 0: el haz va hacia la derecha).
##
## Daño: el de Peligro, pero aquí por defecto es continuo (intervalo_dano = 0: daña cada paso de
## física y confía en la invulnerabilidad del jugador) y sin retroceso. Daña al jugador y a los
## enemigos que andan (los voladores no), y los que andan lo esquivan.
##
## Estructura de la escena (el nodo Laser va en el centro del EmisorA; el haz se ensambla solo
## con la longitud elegida). Dejarlo con escala 1: la separación entre piezas está en píxeles.
##   Laser (Area2D con este script; capa Trampas, máscara Jugador + Enemigos)
##   ├ CollisionShape2D            zona de daño (el script ajusta su tamaño y posición)
##   ├ EmisorA (AnimatedSprite2D)  animaciones "encendido" y "apagado"
##   ├ Centro  (AnimatedSprite2D)  animación "encendido"; el script lo repite "longitud" veces
##   ├ EmisorB (AnimatedSprite2D)  animaciones "encendido" y "apagado"
##   ├ Bloqueo (StaticBody2D, máscara 0)
##   │ ├ EmisorA (CollisionShape2D)  siempre activo (el script lo coloca en el emisor A)
##   │ └ EmisorB (CollisionShape2D)  siempre activo (el script lo coloca en el emisor B)
##   └ BloqueoHaz (StaticBody2D, máscara 0)
##     └ Haz (CollisionShape2D)      solo activo con el láser encendido (el script ajusta su tamaño)
## El haz va en su propio cuerpo para que las sierras lo atraviesen (por el grupo "haz_laser")
## sin atravesar los emisores.
## Las animaciones y su velocidad se hacen en el editor, en el SpriteFrames de cada pieza. El
## centro solo se ve encendido; los emisores cambian entre "encendido" y "apagado".

## Se emite al encenderse (true) o apagarse (false).
signal estado_cambiado(encendido: bool)

## Placas que encienden y apagan el láser: pisar cualquiera alterna. No tienen por qué ser un
## desafío. Vacío = no hay botón.
@export var placas: Array[Placa] = []
## false: empieza apagado y hay que encenderlo (placa, encender()).
@export var empieza_encendido := true

@export_group("Haz")
## Piezas del centro entre los dos emisores. 0 = los dos emisores pegados, sin haz.
@export_range(1, 11) var longitud := 3
## Distancia entre los centros de dos piezas seguidas (píxeles). Igual al ancho de la pieza
## del centro.
@export var separacion := 64.0
## Grosor de la zona que hace daño (píxeles).
@export var grosor_dano := 40.0
## Grosor del haz como obstáculo sólido cuando está encendido (píxeles).
@export var grosor_bloqueo := 24.0

@export_group("Navegación")
## Si los enemigos que andan lo esquivan: los emisores siempre, y el haz mientras está encendido.
@export var bloquear_navegacion := true

## Lado de una casilla en píxeles.
const TAM_CELDA := 64.0

var encendido := false

var _piezas_centro: Array[AnimatedSprite2D] = []

@onready var _emisor_a: AnimatedSprite2D = $EmisorA
@onready var _centro: AnimatedSprite2D = $Centro
@onready var _emisor_b: AnimatedSprite2D = $EmisorB
@onready var _zona_dano: CollisionShape2D = $CollisionShape2D
@onready var _forma_emisor_a: CollisionShape2D = $Bloqueo/EmisorA
@onready var _forma_emisor_b: CollisionShape2D = $Bloqueo/EmisorB
@onready var _cuerpo_haz: StaticBody2D = $BloqueoHaz
@onready var _haz: CollisionShape2D = $BloqueoHaz/Haz


func _init() -> void:
	# Valores de partida distintos a los de Peligro: daño continuo y sin retroceso.
	intervalo_dano = 0.0
	retroceso = false


func _ready() -> void:
	super._ready()
	_cuerpo_haz.add_to_group(&"haz_laser") # las sierras lo atraviesan
	_montar()
	for placa in placas:
		if placa != null:
			placa.activada.connect(alternar)
	_poner_estado(empieza_encendido)


func encender() -> void:
	if not encendido:
		_poner_estado(true)


func apagar() -> void:
	if encendido:
		_poner_estado(false)


func alternar() -> void:
	_poner_estado(not encendido)


## Coloca emisores y centros en fila y ajusta las formas a la longitud elegida.
func _montar() -> void:
	var fin := Vector2((longitud + 1) * separacion, 0.0)
	_emisor_a.position = Vector2.ZERO
	_emisor_b.position = fin

	_piezas_centro = [_centro]
	for i in range(1, longitud):
		var copia := _centro.duplicate() as AnimatedSprite2D
		copia.name = "Centro%d" % (i + 1)
		add_child(copia)
		_piezas_centro.append(copia)
	for i in _piezas_centro.size():
		_piezas_centro[i].position = Vector2((1 + i) * separacion, 0.0)
	if longitud == 0:
		_centro.visible = false # el original sobra; no se cuenta como pieza
		_piezas_centro.clear()

	# Las formas de la escena se comparten entre instancias: se duplican antes de cambiarlas.
	var zona := RectangleShape2D.new()
	zona.size = Vector2(fin.x, grosor_dano)
	_zona_dano.shape = zona
	_zona_dano.position = Vector2(fin.x / 2.0, 0.0)

	var haz := RectangleShape2D.new()
	haz.size = Vector2(fin.x, grosor_bloqueo)
	_haz.shape = haz
	_haz.position = Vector2(fin.x / 2.0, 0.0)

	_forma_emisor_a.position = Vector2.ZERO
	_forma_emisor_b.position = fin


func _poner_estado(nuevo: bool) -> void:
	encendido = nuevo
	activo = nuevo # el daño de Peligro solo funciona encendido
	_haz.set_deferred("disabled", not nuevo)
	_animar(_emisor_a, &"encendido" if nuevo else &"apagado")
	_animar(_emisor_b, &"encendido" if nuevo else &"apagado")
	for pieza in _piezas_centro:
		pieza.visible = nuevo
		if nuevo:
			_animar(pieza, &"encendido")
		else:
			pieza.stop()
	_actualizar_navegacion.call_deferred()
	estado_cambiado.emit(nuevo)


func _animar(pieza: AnimatedSprite2D, animacion: StringName) -> void:
	if pieza.sprite_frames != null and pieza.sprite_frames.has_animation(animacion):
		pieza.play(animacion)


## Los emisores quitan la malla de navegación siempre; el haz solo mientras está encendido.
func _actualizar_navegacion() -> void:
	if not bloquear_navegacion or not is_inside_tree():
		return
	var capa := _buscar_capa()
	if capa == null:
		push_warning("%s no encuentra la CapaSuelo de su sala: no bloqueará la navegación." % name)
		return

	var direccion := Vector2.RIGHT.rotated(global_rotation)
	var largo := (longitud + 1) * separacion
	var emisores: Array[Vector2i] = [
		_celda(capa, global_position),
		_celda(capa, global_position + direccion * largo),
	]
	var haz: Array[Vector2i] = []
	# Se recorre el haz a medio paso de casilla para no saltarse ninguna.
	var pasos := ceili(largo / (TAM_CELDA / 2.0))
	for i in range(1, pasos):
		var celda := _celda(capa, global_position + direccion * (largo * i / pasos))
		if not celda in emisores and not celda in haz:
			haz.append(celda)

	capa.bloquear(emisores)
	if encendido:
		capa.bloquear(haz)
	else:
		capa.desbloquear(haz)


func _celda(capa: CapaSuelo, punto_global: Vector2) -> Vector2i:
	return capa.local_to_map(capa.to_local(punto_global))


func _buscar_capa() -> CapaSuelo:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	if nodo == null:
		return null
	return nodo.get_node_or_null("TileMapLayer") as CapaSuelo
