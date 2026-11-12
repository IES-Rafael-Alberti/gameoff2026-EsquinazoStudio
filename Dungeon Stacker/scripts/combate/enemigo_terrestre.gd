class_name EnemigoTerrestre
extends EnemigoPerseguidor
## Perseguidor que sigue una ruta por la malla de navegación de la sala, en vez de ir en
## línea recta, y esquiva los objetos que llevan un NavigationObstacle2D (cajas, sierras,
## trampas...) y a otros terrestres. Necesita un hijo NavigationAgent2D.
## Hereda la detección (siempre o por radio).

## Cada cuántos segundos recalcula la ruta hacia el jugador.
@export var intervalo_ruta := 0.25

var _tiempo_ruta := 0.0
# Última velocidad que el agente ha calculado como segura (esquivando obstáculos).
var _velocidad_segura := Vector2.ZERO

@onready var _agente: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	super._ready()
	# El agente recorta la velocidad a max_speed: que coincida con la del enemigo.
	_agente.max_speed = velocidad
	_agente.velocity_computed.connect(_on_velocidad_calculada)


func _velocidad_hacia(objetivo: Vector2) -> Vector2:
	_tiempo_ruta -= get_physics_process_delta_time()
	if _tiempo_ruta <= 0.0:
		_tiempo_ruta = intervalo_ruta
		_agente.target_position = objetivo

	var deseada := Vector2.ZERO
	if not _agente.is_navigation_finished():
		var siguiente := _agente.get_next_path_position()
		deseada = (siguiente - global_position).normalized() * velocidad

	if not _agente.avoidance_enabled:
		return deseada
	_agente.set_velocity(deseada)
	return _velocidad_segura


func _on_velocidad_calculada(segura: Vector2) -> void:
	_velocidad_segura = segura
