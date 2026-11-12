class_name InterfazMazmorra
extends CanvasLayer

@onready var _minimapa: Minimapa = $Minimapa
@onready var _etiqueta: Label = $Etiqueta
@onready var _barra_vida: BarraVida = $BarraVida

var _mazmorra: Mazmorra


func _ready() -> void:
	_minimapa.visible = false
	call_deferred("_autoconfigurar")


## Al usarla sola (por ejemplo dentro de una habitación), busca al jugador
## y conecta su vida a la barra. El minimapa queda oculto.
func _autoconfigurar() -> void:
	if _mazmorra != null:
		return
	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return
	var vida: Vida = jugador.get("vida")
	if vida != null:
		_barra_vida.configurar(vida)


## Configuración completa desde Mazmorra: minimapa + barra de vida.
func configurar(mazmorra: Mazmorra, vida: Vida) -> void:
	_mazmorra = mazmorra
	_minimapa.visible = mazmorra != null
	if mazmorra != null:
		_minimapa.configurar(mazmorra)
	if vida != null:
		_barra_vida.configurar(vida)


## Solo la barra de vida, para usar la interfaz sin mazmorra.
func configurar_vida(vida: Vida) -> void:
	if vida != null:
		_barra_vida.configurar(vida)


func refrescar_minimapa() -> void:
	if _mazmorra != null:
		_minimapa.refrescar()


func mostrar_texto(texto: String) -> void:
	_etiqueta.text = texto
