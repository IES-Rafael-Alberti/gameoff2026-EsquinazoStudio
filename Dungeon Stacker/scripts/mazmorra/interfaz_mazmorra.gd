class_name InterfazMazmorra
extends CanvasLayer

@onready var _minimapa: Minimapa = $Minimapa
@onready var _barra_vida: BarraVida = $BarraVida
## Etiqueta con el número de piezas del tetris (el icono lo pones tú al lado, en el editor).
@export var etiqueta_piezas: Label
@onready var _llave: TextureRect = get_node_or_null("Llave") as TextureRect
## AnimationPlayer de la interfaz (nodo hijo "AnimationPlayer").
@onready var _animaciones: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer
## Nombre de la animación que se reproduce cada vez que el jugador recibe daño (cualquier daño,
## también al caer al vacío). Si está vacío o no existe en el AnimationPlayer, no hace nada.
@export var animacion_dano: StringName = &"dano"

var _mazmorra: Mazmorra
var _vida_escuchada: Vida

func _ready() -> void:
	_minimapa.visible = false
	if _llave != null:
		_llave.visible = false
	call_deferred("_autoconfigurar")

func _autoconfigurar() -> void:
	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador != null:
		_conectar_llave(jugador)
		if _mazmorra == null:
			var vida: Vida = jugador.get("vida")
			if vida != null:
				_barra_vida.configurar(vida)
				_escuchar_dano(vida)

func configurar(mazmorra: Mazmorra, vida: Vida) -> void:
	_mazmorra = mazmorra
	_minimapa.visible = mazmorra != null
	if mazmorra != null:
		_minimapa.configurar(mazmorra)
	if vida != null:
		_barra_vida.configurar(vida)
		_escuchar_dano(vida)
	var jugador := get_tree().get_first_node_in_group("jugador")
	_conectar_llave(jugador)

func refrescar_minimapa() -> void:
	if _mazmorra != null:
		_minimapa.refrescar()

func mostrar_piezas(total: int) -> void:
	if etiqueta_piezas != null:
		etiqueta_piezas.text = str(total)

## Reproduce la animación de daño cada vez que esta vida recibe daño.
func _escuchar_dano(vida: Vida) -> void:
	if _vida_escuchada == vida:
		return
	if is_instance_valid(_vida_escuchada) and _vida_escuchada.danada.is_connected(_on_danada):
		_vida_escuchada.danada.disconnect(_on_danada)
	_vida_escuchada = vida
	vida.danada.connect(_on_danada)

func _on_danada(_cantidad: int) -> void:
	if _animaciones == null or not _animaciones.has_animation(animacion_dano):
		return
	_animaciones.stop() # si aún sonaba la anterior, empieza de nuevo
	_animaciones.play(animacion_dano)

func _conectar_llave(jugador: Node) -> void:
	if jugador == null or not jugador.has_signal("llave_cambiada"):
		return
	if not jugador.is_connected("llave_cambiada", _actualizar_llave):
		jugador.connect("llave_cambiada", _actualizar_llave)
	_actualizar_llave(jugador.get("tiene_llave") == true)

func _actualizar_llave(tiene: bool) -> void:
	if _llave != null:
		_llave.visible = tiene
