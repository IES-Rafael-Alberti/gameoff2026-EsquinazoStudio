class_name Placa
extends Area2D
## Botón de suelo. Se activa cuando algo válido está encima: el jugador, una caja o ambos.
## Por sí sola no resuelve nada: la usa un puzle (PuzleBotones, PuzleSecuencia...).

signal activada
signal desactivada

## Lado de la celda en píxeles: el sprite se escala a este tamaño.
const TAM_CELDA := 64.0

@export_group("Sprites")
## Botón levantado (sin activar).
@export var sprite_levantada: Texture2D
## Botón hundido (activado).
@export var sprite_hundida: Texture2D

@export_group("Comportamiento")
## Se activa al pisarla el jugador.
@export var activa_jugador := true
## Se activa al ponerle una caja encima.
@export var activa_caja := true
## Si es true, una vez activada se queda hundida aunque se suelte.
@export var se_queda_activa := false

var activa := false

var _ocupantes: Array[Node2D] = []

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_cuerpo_entro)
	body_exited.connect(_on_cuerpo_salio)
	_aplicar_sprite()


## Vuelve a estar levantada. Si algo válido sigue encima, hay que salir y volver a entrar.
func reiniciar() -> void:
	_ocupantes.clear()
	_poner_activa(false)	


## Deja la placa hundida sin emitir señales (sala ya resuelta).
func forzar_activa() -> void:
	activa = true
	_aplicar_sprite()


func _on_cuerpo_entro(cuerpo: Node2D) -> void:
	if _es_valido(cuerpo) and not cuerpo in _ocupantes:
		_ocupantes.append(cuerpo)
		_evaluar()


func _on_cuerpo_salio(cuerpo: Node2D) -> void:
	if cuerpo in _ocupantes:
		_ocupantes.erase(cuerpo)
		_evaluar()


func _es_valido(cuerpo: Node2D) -> bool:
	return (activa_jugador and cuerpo.is_in_group("jugador")) \
		or (activa_caja and cuerpo.is_in_group("caja"))


func _evaluar() -> void:
	if not _ocupantes.is_empty():
		_poner_activa(true)
	elif not se_queda_activa:
		_poner_activa(false)


func _poner_activa(valor: bool) -> void:
	if valor == activa:
		return
	activa = valor
	_aplicar_sprite()
	if activa:
		activada.emit()
	else:
		desactivada.emit()


func _aplicar_sprite() -> void:
	var textura := sprite_hundida if activa else sprite_levantada
	if textura == null:
		textura = sprite_levantada
	_sprite.texture = textura
	if textura != null:
		_sprite.scale = Vector2.ONE * TAM_CELDA / textura.get_size()
