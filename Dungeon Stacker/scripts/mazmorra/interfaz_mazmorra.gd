class_name InterfazMazmorra
extends CanvasLayer

@onready var _minimapa: Minimapa = $Minimapa
@onready var _etiqueta: Label = $Etiqueta
@onready var _barra_vida: BarraVida = $BarraVida
@onready var _llave: TextureRect = get_node_or_null("Llave") as TextureRect

var _mazmorra: Mazmorra


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


func configurar(mazmorra: Mazmorra, vida: Vida) -> void:
	_mazmorra = mazmorra
	_minimapa.visible = mazmorra != null
	if mazmorra != null:
		_minimapa.configurar(mazmorra)
	if vida != null:
		_barra_vida.configurar(vida)
	var jugador := get_tree().get_first_node_in_group("jugador")
	_conectar_llave(jugador)


func configurar_vida(vida: Vida) -> void:
	if vida != null:
		_barra_vida.configurar(vida)


func refrescar_minimapa() -> void:
	if _mazmorra != null:
		_minimapa.refrescar()


func mostrar_texto(texto: String) -> void:
	_etiqueta.text = texto


func _conectar_llave(jugador: Node) -> void:
	if jugador == null or not jugador.has_signal("llave_cambiada"):
		return
	if not jugador.is_connected("llave_cambiada", _actualizar_llave):
		jugador.connect("llave_cambiada", _actualizar_llave)
	_actualizar_llave(jugador.get("tiene_llave") == true)


func _actualizar_llave(tiene: bool) -> void:
	if _llave != null:
		_llave.visible = tiene
