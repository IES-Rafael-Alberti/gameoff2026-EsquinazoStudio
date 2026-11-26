class_name JugadorAtacar
extends JugadorEstado
## Ataque en 3 fases: anticipación, golpe y recuperación.
## El cuerpo se acelera para durar "duracion_ataque"; la onda solo se ve durante el golpe.

@export_range(0.05, 2.0, 0.01, "suffix:s") var duracion_ataque := 0.4
## Segundos que el Area2D está activo. Si lo cambias, pon Speed del SpriteFrames "Onda" = 4 / duracion_golpe.
@export_range(0.01, 1.0, 0.01, "suffix:s") var duracion_golpe := 0.133

enum Fase { ANTICIPACION, GOLPE, RECUPERACION }

var _tiempo := 0.0
var _fase := Fase.ANTICIPACION
var _inicio_golpe := 0.0
var _fin_golpe := 0.0


func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	_tiempo = 0.0
	_fase = Fase.ANTICIPACION
	_inicio_golpe = maxf(0.0, (duracion_ataque - duracion_golpe) * 0.5)
	_fin_golpe = _inicio_golpe + duracion_golpe
	jugador.animar("Attack")
	jugador.sprite.speed_scale = _escala_velocidad()
	jugador.colocar_zona_golpe()
	jugador.sprite.animation_finished.connect(_on_animacion_terminada)


func salir() -> void:
	jugador.terminar_golpe()
	jugador.onda_ataque.stop()
	jugador.onda_ataque.visible = false
	jugador.sprite.speed_scale = 1.0
	if jugador.sprite.animation_finished.is_connected(_on_animacion_terminada):
		jugador.sprite.animation_finished.disconnect(_on_animacion_terminada)


func fisica(delta: float) -> void:
	_tiempo += delta
	jugador.colocar_zona_golpe()
	if _fase == Fase.ANTICIPACION and _tiempo >= _inicio_golpe:
		_empezar_golpe()
	if _fase == Fase.GOLPE and _tiempo > _inicio_golpe:
		jugador.golpear()
		if _tiempo >= _fin_golpe:
			_terminar_golpe()
	if not jugador.avanzar_retroceso(delta):
		jugador.velocity = Vector2.ZERO
		jugador.move_and_slide()


func _empezar_golpe() -> void:
	_fase = Fase.GOLPE
	jugador.empezar_golpe()
	jugador.onda_ataque.visible = true
	jugador.onda_ataque.play("Onda")


func _terminar_golpe() -> void:
	_fase = Fase.RECUPERACION
	jugador.terminar_golpe()
	jugador.onda_ataque.stop()
	jugador.onda_ataque.visible = false


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
