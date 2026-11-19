extends Node
## Autoload "Musica" (se registra como ESCENA: Musica.tscn con este script en el nodo raíz).
##
## Un único AudioStreamPlayer. En el juego reproduce un AudioStreamSynchronized con las dos
## canciones del bioma (Tetris y Mazmorra) sonando SIEMPRE a la vez, en sincronía exacta; solo se
## oye una, y cambiar de modo es un fundido de volumen entre ellas, sin buscar posición.
## Al cambiar de bioma se cargan las dos canciones del bioma nuevo y arrancan desde el principio.

enum Modo { TETRIS, MAZMORRA }

@export_group("Canciones")
@export var cancion_menu: AudioStream
## Las dos canciones de cada bioma. Un bioma sin entrada no tiene música.
@export var pistas_biomas: Array[PistasBioma] = []
## Pone el bucle a las canciones al cargarlas (así no hace falta marcarlo en cada .ogg).
@export var repetir := true

@export_group("Volumen y fundidos")
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var volumen_db := 0.0
## Duración (s) del cruce entre la canción de Tetris y la de Mazmorra al cambiar de modo. 0 = corte.
@export_range(0.0, 5.0, 0.05, "suffix:s") var fundido_modo := 0.4
## Duración (s) de CADA fundido (salida y entrada) al cambiar de bioma. 0 = corte.
@export_range(0.0, 5.0, 0.05, "suffix:s") var fundido_bioma := 0.8
## Duración (s) de CADA fundido al pasar del menú al juego o al revés. 0 = corte.
@export_range(0.0, 5.0, 0.05, "suffix:s") var fundido_menu := 0.8

const SILENCIO_DB := -80.0

## Reproductor de la escena Musica.tscn: ahí se elige el bus (Musica) en el inspector.
@onready var _player: AudioStreamPlayer = $AudioStreamPlayer
var _sync: AudioStreamSynchronized
var _tween: Tween
var _tween_modo: Tween

var _en_menu := false
var _juego_cargado := false
var _modo := Modo.MAZMORRA
var _bioma := -1
## 0 = suena solo la de Mazmorra, 1 = suena solo la de Tetris.
var _mezcla := 0.0


func _ready() -> void:
	# Que la música siga sonando con el árbol en pausa (pantalla de muerte, etc.).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player.volume_db = SILENCIO_DB


## Suena la canción del menú (con fundido si venía de otra cosa).
func reproducir_menu() -> void:
	if _en_menu:
		return
	_en_menu = true
	_juego_cargado = false
	_transicion(fundido_menu, _cargar_menu)


## Empieza la música del juego desde el principio, en el bioma y el modo indicados.
func iniciar_juego(bioma: int, modo: Modo) -> void:
	_en_menu = false
	_bioma = bioma
	_modo = modo
	_mezcla = 1.0 if modo == Modo.TETRIS else 0.0
	_transicion(fundido_menu, _cargar_juego)


## Cambia entre la canción de Tetris y la de Mazmorra, en el mismo punto de la canción.
func cambiar_modo(modo: Modo) -> void:
	_modo = modo
	var objetivo := 1.0 if modo == Modo.TETRIS else 0.0
	if not _juego_cargado:
		_mezcla = objetivo
		return
	if _tween_modo != null:
		_tween_modo.kill()
	if fundido_modo <= 0.0:
		_poner_mezcla(objetivo)
		return
	_tween_modo = create_tween()
	_tween_modo.tween_method(_poner_mezcla, _mezcla, objetivo, fundido_modo)


## Cambia las canciones al bioma indicado, empezando desde el principio. Mismo bioma = nada.
func cambiar_bioma(bioma: int) -> void:
	if bioma == _bioma:
		return
	_bioma = bioma
	if _en_menu:
		return
	_transicion(fundido_bioma, _cargar_juego)


## Fundido de salida (si estaba sonando), carga lo nuevo y fundido de entrada.
func _transicion(duracion: float, cargar: Callable) -> void:
	if _tween != null:
		_tween.kill()
	if duracion <= 0.0:
		cargar.call()
		_poner_volumen(1.0)
		return
	_tween = create_tween()
	if _player.playing:
		_tween.tween_method(_poner_volumen, _volumen_lineal(), 0.0, duracion)
	_tween.tween_callback(cargar)
	_tween.tween_method(_poner_volumen, 0.0, 1.0, duracion)


func _cargar_menu() -> void:
	_juego_cargado = false
	_sync = null
	_player.stream = _con_bucle(cancion_menu)
	_player.play()


func _cargar_juego() -> void:
	var pistas := _pistas_de(_bioma)
	if pistas == null:
		push_warning("Musica: no hay canciones para el bioma %s." % _bioma)
		_player.stop()
		_juego_cargado = false
		return
	_sync = AudioStreamSynchronized.new()
	_sync.stream_count = 2
	_sync.set_sync_stream(0, _con_bucle(pistas.mazmorra))
	_sync.set_sync_stream(1, _con_bucle(pistas.tetris))
	_juego_cargado = true
	# Con un modo ya decidido, arranca directamente con la mezcla correcta.
	_mezcla = 1.0 if _modo == Modo.TETRIS else 0.0
	_poner_mezcla(_mezcla)
	_player.stream = _sync
	_player.play()


## Reparte el volumen entre la pista de Mazmorra (0) y la de Tetris (1). t = 1 -> solo Tetris.
func _poner_mezcla(t: float) -> void:
	_mezcla = t
	if _sync == null:
		return
	_sync.set_sync_stream_volume(0, _a_db(1.0 - t))
	_sync.set_sync_stream_volume(1, _a_db(t))


## Volumen general del reproductor, de 0 (silencio) a 1 (volumen_db).
func _poner_volumen(lineal: float) -> void:
	_player.volume_db = _a_db(lineal) + volumen_db if lineal > 0.0001 else SILENCIO_DB


func _volumen_lineal() -> float:
	if _player.volume_db <= SILENCIO_DB:
		return 0.0
	return clampf(db_to_linear(_player.volume_db - volumen_db), 0.0, 1.0)


func _a_db(lineal: float) -> float:
	return SILENCIO_DB if lineal <= 0.0001 else linear_to_db(lineal)


func _pistas_de(bioma: int) -> PistasBioma:
	for entrada in pistas_biomas:
		if entrada != null and entrada.bioma == bioma:
			return entrada
	return null


func _con_bucle(cancion: AudioStream) -> AudioStream:
	if repetir and cancion is AudioStreamOggVorbis:
		cancion.loop = true
	return cancion
