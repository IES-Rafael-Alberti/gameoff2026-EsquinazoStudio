class_name JugadorAtacar
extends JugadorEstado
## Ataque: reproduce la animación de ataque, hace el golpe pasado retardo_golpe y no se mueve.
## Si el jugador recibe daño mientras ataca, el ataque sigue (con el retroceso aplicado).
## La animación "Attack_<dirección>" no debe estar en bucle: al terminar vuelve a Inactivo.
## La velocidad de la animación se ajusta sola para que dure "duracion_ataque" segundos.

## Segundos que dura el ataque completo (lo que tarda en volver a poder moverse).
@export_range(0.05, 2.0, 0.01, "suffix:s") var duracion_ataque := 0.4

var _tiempo := 0.0
var _golpe_dado := false


func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	_tiempo = 0.0
	_golpe_dado = false
	jugador.animar("Attack")
	jugador.sprite.speed_scale = _escala_velocidad()
	jugador.sprite.animation_finished.connect(_on_animacion_terminada)


func salir() -> void:
	jugador.sprite.speed_scale = 1.0
	if jugador.sprite.animation_finished.is_connected(_on_animacion_terminada):
		jugador.sprite.animation_finished.disconnect(_on_animacion_terminada)


func fisica(delta: float) -> void:
	_tiempo += delta
	if not _golpe_dado and _tiempo >= jugador.retardo_golpe:
		_golpe_dado = true
		jugador.golpear()
	if not jugador.avanzar_retroceso(delta):
		jugador.velocity = Vector2.ZERO
		jugador.move_and_slide()


func _on_animacion_terminada() -> void:
	_terminar(INACTIVO)


## Cuánto acelerar la animación actual para que dure "duracion_ataque" segundos.
func _escala_velocidad() -> float:
	var frames := jugador.sprite.sprite_frames
	var nombre := jugador.sprite.animation
	if frames == null or not frames.has_animation(nombre):
		return 1.0
	var fps := frames.get_animation_speed(nombre)
	if fps <= 0.0:
		return 1.0
	var unidades := 0.0
	for i in frames.get_frame_count(nombre):
		unidades += frames.get_frame_duration(nombre, i)
	var duracion_original := unidades / fps
	return duracion_original / maxf(duracion_ataque, 0.01)
