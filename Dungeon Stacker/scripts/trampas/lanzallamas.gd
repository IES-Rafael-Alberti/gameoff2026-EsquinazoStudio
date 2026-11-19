class_name Lanzallamas
extends Peligro
## Lanzallamas: un arma que lanza una llama recta hacia donde apunta (con rotation = 0, hacia
## la derecha; al rotar el nodo rota la llama). La llama daña al jugador y a los enemigos que
## andan (los voladores no) y atraviesa muros y cajas.
##
## Ciclo: [retardo_inicio] -> espera -> aviso (el arma parpadea en rojo) -> llama activa -> espera
## -> aviso -> ... Con "infinita" la llama se queda encendida para siempre tras el primer aviso.
## Se puede apagar y encender desde fuera (puzles, placas): encender(), apagar(), alternar(),
## o arrastrando una o varias Placas al campo "placas".
##
## El daño es el de Peligro, pero aquí por defecto es continuo (intervalo_dano = 0: daña cada
## paso de física y confía en la invulnerabilidad del jugador) y sin retroceso.
##
## Estructura de la escena (la llama se ensambla sola con la longitud elegida):
##   Lanzallamas (Area2D con este script; capa Trampas, máscara Jugador + Enemigos)
##   ├ CollisionShape2D (RectangleShape2D, cualquier tamaño: el script lo ajusta)
##   ├ Arma (Sprite2D o AnimatedSprite2D)
##   └ Llama (Node2D)
##     ├ Inicio (AnimatedSprite2D: animación en bucle de 2 fotogramas)
##     ├ Centro (AnimatedSprite2D: ídem; el script lo repite "longitud" veces)
##     └ Fin    (AnimatedSprite2D: ídem)
## Las animaciones y su velocidad se hacen en el editor, en el SpriteFrames de cada pieza.
## Dejar el Lanzallamas con escala 1: la separación entre piezas está en píxeles.

enum Fase { APAGADA, ESPERANDO_JUGADOR, RETARDO, ESPERA, AVISO, ACTIVA }

## Placas que encienden y apagan el lanzallamas: pisar cualquiera de ellas alterna. No tienen
## por qué ser un desafío. Vacío = no hay botón.
@export var placas: Array[Placa] = []
## false: empieza apagado y hay que encenderlo (placa, encender()).
@export var empieza_encendido := true

@export_group("Llama")
## Piezas del centro entre el inicio y el fin. 0 = solo arma + inicio + fin.
@export_range(0, 30) var longitud := 3
## Distancia entre los centros de dos piezas seguidas (píxeles). Igual al tamaño de la pieza.
@export var separacion := 64.0
## Ancho de la zona que hace daño (píxeles).
@export var grosor_dano := 40.0

@export_group("Tiempos")
## Segundos desde que el jugador entra en la sala hasta el primer aviso. 0 = empieza al cargar
## la sala.
@export var retardo_inicio := 0.0
## Segundos entre que acaba la llama y empieza el siguiente aviso.
@export var tiempo_espera := 2.0
## Segundos que dura la llama encendida en cada ciclo.
@export var duracion_activa := 2.0
## Si está marcado, la llama no se apaga: tras el primer aviso se queda encendida para siempre
## (hasta que se apague desde fuera).
@export var infinita := false

@export_group("Aviso")
## Segundos que parpadea el arma en rojo antes de lanzar la llama. 0 = sin aviso.
@export var duracion_aviso := 0.8
## Cuántas veces parpadea durante el aviso.
@export_range(1, 20) var parpadeos_aviso := 3
## Color del arma en la parte roja del parpadeo.
@export var color_aviso := Color(1, 0.2, 0.2)

var fase := Fase.APAGADA

var _tiempo := 0.0
var _habitacion: Habitacion
var _piezas_centro: Array[Node2D] = []

@onready var _arma: CanvasItem = $Arma
@onready var _llama: Node2D = $Llama
@onready var _inicio: Node2D = $Llama/Inicio
@onready var _centro: Node2D = $Llama/Centro
@onready var _fin: Node2D = $Llama/Fin
@onready var _forma: CollisionShape2D = $CollisionShape2D


func _init() -> void:
	# Valores de partida distintos a los de Peligro: daño continuo y sin retroceso.
	intervalo_dano = 0.0
	retroceso = false


func _ready() -> void:
	super._ready()
	_montar_llama()
	activo = false # el daño solo está activo mientras la llama está encendida
	_poner_llama(false)

	for placa in placas:
		if placa != null:
			placa.activada.connect(alternar)
	if not empieza_encendido:
		return

	if retardo_inicio > 0.0:
		_habitacion = _buscar_habitacion()
		if _habitacion == null:
			_cambiar_fase(Fase.RETARDO) # escena suelta: cuenta ya
		else:
			fase = Fase.ESPERANDO_JUGADOR
			_habitacion.jugador_entro.connect(_on_jugador_entro, CONNECT_ONE_SHOT)
	else:
		_cambiar_fase(Fase.AVISO)


# Sin awaits: la sala se destruye al salir de ella y un temporizador pendiente intentaría
# seguir sobre un nodo que ya no existe.
func _physics_process(delta: float) -> void:
	super._physics_process(delta) # daño de Peligro (solo si activo)
	if fase == Fase.APAGADA or fase == Fase.ESPERANDO_JUGADOR:
		return
	if fase == Fase.ACTIVA and infinita:
		return

	_tiempo -= delta
	if fase == Fase.AVISO:
		_parpadear()
	if _tiempo > 0.0:
		return

	match fase:
		Fase.RETARDO, Fase.ESPERA:
			_cambiar_fase(Fase.AVISO)
		Fase.AVISO:
			_cambiar_fase(Fase.ACTIVA)
		Fase.ACTIVA:
			_cambiar_fase(Fase.ESPERA)


## Lo enciende desde fuera: empieza por el aviso, sin esperar el retardo. No hace nada si ya
## está en marcha.
func encender() -> void:
	if fase == Fase.APAGADA or fase == Fase.ESPERANDO_JUGADOR:
		_cambiar_fase(Fase.AVISO)


## Lo apaga desde fuera: la llama desaparece y el ciclo se para.
func apagar() -> void:
	_cambiar_fase(Fase.APAGADA)


func alternar() -> void:
	if fase == Fase.APAGADA or fase == Fase.ESPERANDO_JUGADOR:
		encender()
	else:
		apagar()


func _on_jugador_entro() -> void:
	if fase == Fase.ESPERANDO_JUGADOR:
		_cambiar_fase(Fase.RETARDO)


func _cambiar_fase(nueva: Fase) -> void:
	fase = nueva
	match nueva:
		Fase.APAGADA:
			activo = false
			_poner_llama(false)
			_arma.modulate = Color.WHITE
		Fase.RETARDO:
			_tiempo = retardo_inicio
		Fase.ESPERA:
			activo = false
			_poner_llama(false)
			_arma.modulate = Color.WHITE
			_tiempo = tiempo_espera
		Fase.AVISO:
			_tiempo = duracion_aviso
			_parpadear()
		Fase.ACTIVA:
			_arma.modulate = Color.WHITE
			_tiempo = duracion_activa
			_poner_llama(true)
			activo = true


## El arma alterna entre su color y el rojo durante el aviso.
func _parpadear() -> void:
	if duracion_aviso <= 0.0:
		return
	var avance := 1.0 - clampf(_tiempo / duracion_aviso, 0.0, 1.0)
	var en_rojo := int(avance * parpadeos_aviso * 2.0) % 2 == 0
	_arma.modulate = color_aviso if en_rojo else Color.WHITE


## Coloca arma, inicio, centros y fin en fila, y ajusta la zona de daño a su longitud.
func _montar_llama() -> void:
	_arma.position = Vector2.ZERO
	_inicio.position = Vector2(separacion, 0.0)

	_piezas_centro = [_centro]
	for i in range(1, longitud):
		var copia := _centro.duplicate() as Node2D
		copia.name = "Centro%d" % (i + 1)
		_llama.add_child(copia)
		_piezas_centro.append(copia)
	for i in _piezas_centro.size():
		_piezas_centro[i].position = Vector2((2 + i) * separacion, 0.0)
	if longitud == 0:
		_centro.visible = false # el original sobra; no se cuenta como pieza
		_piezas_centro.clear()

	_fin.position = Vector2((2 + longitud) * separacion, 0.0)

	# La zona va desde el borde del inicio hasta el final del fin. La forma de la escena se
	# comparte entre todas las instancias: se duplica antes de cambiarla.
	var anchura := (longitud + 2) * separacion
	var forma := RectangleShape2D.new()
	forma.size = Vector2(anchura, grosor_dano)
	_forma.shape = forma
	_forma.position = Vector2(separacion / 2.0 + anchura / 2.0, 0.0)


## Muestra u oculta la llama y arranca o para las animaciones de sus piezas.
func _poner_llama(encendida: bool) -> void:
	_llama.visible = encendida
	var piezas: Array[Node2D] = [_inicio, _fin]
	piezas.append_array(_piezas_centro)
	for pieza in piezas:
		var animada := pieza as AnimatedSprite2D
		if animada == null:
			continue
		if encendida:
			animada.play()
		else:
			animada.stop()


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
