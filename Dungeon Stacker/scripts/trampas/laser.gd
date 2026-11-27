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
## Una caja o una pared en el haz lo corta (ver "corte"): las piezas del centro afectadas se
## apagan y dejan de dañar y bloquear. Las cajas pueden entrar en el haz (las empuja el jugador).
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
@export_range(1, 50) var longitud := 3
## Distancia entre los centros de dos piezas seguidas (píxeles). Igual al ancho de la pieza
## del centro.
@export var separacion := 64.0
## Grosor de la zona que hace daño (píxeles).
@export var grosor_dano := 40.0
## Grosor del haz como obstáculo sólido cuando está encendido (píxeles).
@export var grosor_bloqueo := 24.0

enum Corte {
	SOLO_EMISOR_A, ## El haz sale del emisor A: lo que hay después de la caja se apaga.
	DESDE_AMBOS_EMISORES, ## Cada emisor llega hasta la caja: solo se apaga donde ella está.
}

@export_group("Corte")
## Cómo corta una caja o una pared que hay en el haz. El emisor A es el origen del nodo Laser.
@export var corte := Corte.SOLO_EMISOR_A

@export_group("Navegación")
## Si los enemigos que andan lo esquivan: los emisores siempre, y el haz mientras está encendido.
@export var bloquear_navegacion := true

## Lado de una casilla en píxeles.
const TAM_CELDA := 64.0

var encendido := false

var _piezas_centro: Array[AnimatedSprite2D] = []
var _zona_dano_b: CollisionShape2D # segundo tramo de daño (solo con corte desde ambos emisores)
var _haz_b: CollisionShape2D # segundo tramo sólido
var _forma_consulta: RectangleShape2D # área que se mira en cada pieza para ver si está cortada
var _largo := 0.0
var _cortadas: Array[bool] = []
# Tramos (inicio, fin) en píxeles desde el emisor A; fin <= inicio = no hay tramo.
var _tramo_a := Vector2.ZERO
var _tramo_b := Vector2.ZERO

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
	add_to_group(&"laser") # la sala guarda su estado
	_cuerpo_haz.add_to_group(&"haz_laser") # las sierras lo atraviesan
	_montar()
	for placa in placas:
		if placa != null:
			placa.activada.connect(alternar)
	_poner_estado(empieza_encendido)


func _physics_process(delta: float) -> void:
	super._physics_process(delta) # daño por contacto
	if encendido:
		_actualizar_corte()


## La sala resuelta lo deja como estaba al salir.
func restaurar(estaba_encendido: bool) -> void:
	_poner_estado(estaba_encendido)


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

	# Las formas de la escena se comparten entre instancias: se crean nuevas antes de cambiarlas.
	_zona_dano.shape = RectangleShape2D.new()
	_haz.shape = RectangleShape2D.new()
	_zona_dano_b = CollisionShape2D.new()
	_zona_dano_b.shape = RectangleShape2D.new()
	_zona_dano_b.disabled = true
	add_child(_zona_dano_b)
	_haz_b = CollisionShape2D.new()
	_haz_b.shape = RectangleShape2D.new()
	_haz_b.disabled = true
	_cuerpo_haz.add_child(_haz_b)

	_forma_consulta = RectangleShape2D.new()
	_forma_consulta.size = Vector2(maxf(separacion - 8.0, 1.0), grosor_bloqueo)
	_largo = fin.x
	_cortadas.resize(_piezas_centro.size())
	_cortadas.fill(false)
	_tramo_a = Vector2(0.0, _largo)
	_tramo_b = Vector2.ZERO

	_forma_emisor_a.position = Vector2.ZERO
	_forma_emisor_b.position = fin


func _poner_estado(nuevo: bool) -> void:
	encendido = nuevo
	activo = nuevo # el daño de Peligro solo funciona encendido
	_aplicar_tramos()
	_animar(_emisor_a, &"encendido" if nuevo else &"apagado")
	_animar(_emisor_b, &"encendido" if nuevo else &"apagado")
	for pieza in _piezas_centro:
		if nuevo:
			_animar(pieza, &"encendido")
		else:
			pieza.stop()
	_actualizar_corte(true)
	_actualizar_navegacion.call_deferred()
	estado_cambiado.emit(nuevo)


## Mira qué piezas del haz tienen una caja o una pared y recalcula los tramos que siguen activos.
func _actualizar_corte(forzar := false) -> void:
	var nuevas: Array[bool] = []
	for i in _piezas_centro.size():
		nuevas.append(encendido and _pieza_cortada(i))
	if not forzar and nuevas == _cortadas:
		return
	_cortadas = nuevas

	var primera := -1
	var ultima := -1
	for i in _cortadas.size():
		if _cortadas[i]:
			if primera < 0:
				primera = i
			ultima = i

	var n := _piezas_centro.size()
	var con_b := corte == Corte.DESDE_AMBOS_EMISORES
	if primera < 0:
		_tramo_a = Vector2(0.0, _largo)
		_tramo_b = Vector2.ZERO
	else:
		# Pieza j: centro en (j + 1) * separacion; ocupa media separación a cada lado.
		_tramo_a = Vector2(0.0, primera * separacion + separacion / 2.0) if primera > 0 else Vector2.ZERO
		_tramo_b = Vector2.ZERO
		if con_b and ultima < n - 1:
			_tramo_b = Vector2((ultima + 1.5) * separacion, _largo)

	# Con el corte solo desde el emisor A, el B no recibe haz: se ve apagado mientras esté cortado.
	var b_apagado := encendido and primera >= 0 and not con_b
	_animar(_emisor_b, &"apagado" if (b_apagado or not encendido) else &"encendido")

	for i in n:
		var visible_ahora := encendido
		if primera >= 0:
			visible_ahora = encendido and (i < primera or (con_b and i > ultima))
		_piezas_centro[i].visible = visible_ahora
	_aplicar_tramos()


## ¿Hay una caja o una pared en la pieza i del haz?
func _pieza_cortada(i: int) -> bool:
	var direccion := Vector2.RIGHT.rotated(global_rotation)
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = _forma_consulta
	consulta.transform = Transform2D(global_rotation, global_position + direccion * (i + 1) * separacion)
	consulta.collision_mask = Capas.MUROS | Capas.CAJAS
	consulta.exclude = _propios()
	return not get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()


## Cuerpos que el corte ignora: este láser (emisores y haz) y el haz de cualquier otro láser.
func _propios() -> Array[RID]:
	var rids: Array[RID] = [get_rid(), $Bloqueo.get_rid(), _cuerpo_haz.get_rid()]
	for haz in get_tree().get_nodes_in_group(&"haz_laser"):
		if haz is CollisionObject2D:
			rids.append(haz.get_rid())
	return rids


## Coloca las zonas de daño y los obstáculos del haz según los tramos activos.
func _aplicar_tramos() -> void:
	_poner_tramo(_zona_dano, _haz, _tramo_a)
	_poner_tramo(_zona_dano_b, _haz_b, _tramo_b)


func _poner_tramo(zona: CollisionShape2D, haz: CollisionShape2D, tramo: Vector2) -> void:
	var hay := encendido and tramo.y > tramo.x
	zona.set_deferred("disabled", not hay)
	haz.set_deferred("disabled", not hay)
	if not hay:
		return
	var largo := tramo.y - tramo.x
	var centro := Vector2((tramo.x + tramo.y) / 2.0, 0.0)
	(zona.shape as RectangleShape2D).size = Vector2(largo, grosor_dano)
	zona.position = centro
	(haz.shape as RectangleShape2D).size = Vector2(largo, grosor_bloqueo)
	haz.position = centro


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
