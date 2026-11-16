class_name EnemigoEstadosTerrestre
extends EnemigoEstados
## EnemigoEstados que, al ir hacia un punto (perseguir, volver a su sitio), sigue una ruta por
## la malla de navegación de la sala y esquiva los objetos con NavigationObstacle2D y a otros
## terrestres. Necesita un hijo NavigationAgent2D (Path Postprocessing = Edge Centered).

## Cada cuántos segundos recalcula la ruta.
@export var intervalo_ruta := 0.25

var _tiempo_ruta := 0.0
# Última velocidad que el agente ha calculado como segura (esquivando obstáculos).
var _velocidad_segura := Vector2.ZERO

@onready var _agente: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	super._ready()
	_agente.velocity_computed.connect(_on_velocidad_calculada)


func mover_hacia(destino: Vector2, rapidez: float) -> void:
	# El agente recorta la velocidad a max_speed: que coincida con la del movimiento.
	_agente.max_speed = rapidez
	_tiempo_ruta -= get_physics_process_delta_time()
	if _tiempo_ruta <= 0.0:
		_tiempo_ruta = intervalo_ruta
		_agente.target_position = destino

	var deseada := Vector2.ZERO
	if not _agente.is_navigation_finished():
		var siguiente := _agente.get_next_path_position()
		deseada = (siguiente - global_position).normalized() * rapidez

	if _agente.avoidance_enabled:
		_agente.set_velocity(deseada)
		deseada = _velocidad_segura
	mover(deseada)


func _on_velocidad_calculada(segura: Vector2) -> void:
	_velocidad_segura = segura
