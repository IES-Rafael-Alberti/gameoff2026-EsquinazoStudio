class_name BaldosaRota
extends Area2D
## Baldosa que se rompe cuando el jugador la pisa y sale de ella. Al romperse, su sprite se
## oculta y se ve lo que haya debajo en el TileMapLayer de la sala: ahí hay que dejar puesta la
## casilla de vacío del bioma (así no hace falta dar aquí qué casilla es el vacío).

signal rota(baldosa: BaldosaRota)

var _jugador_dentro := false
var _rota := false

@onready var _sprite: Sprite2D = $Sprite2D
## Trozo de malla de navegación de la baldosa: activo mientras está entera, para que los
## enemigos que andan la puedan cruzar, y desactivado cuando se rompe (es un hueco).
@onready var _navegacion: NavigationRegion2D = $Navegacion


func _ready() -> void:
	add_to_group("baldosa_rota")
	collision_layer = 0
	collision_mask = 2 # capa del jugador
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		_jugador_dentro = true


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("jugador") or not _jugador_dentro:
		return
	_jugador_dentro = false
	if _rota:
		return
	_rota = true
	_sprite.visible = false
	_navegacion.enabled = false
	rota.emit(self)


## La sala la devuelve a su estado inicial.
func restaurar() -> void:
	_rota = false
	_jugador_dentro = false
	_sprite.visible = true
	_navegacion.enabled = true
