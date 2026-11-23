class_name JugadorInactivo
extends JugadorEstado
## Parado. Se queda en el primer fotograma de la caminata de la última dirección y, pasado un
## tiempo sin moverse, pasa a la animación de Idle (de frente).

## Segundos parado hasta que empieza la animación de Idle.
@export_range(0.0, 30.0, 0.1, "suffix:s") var segundos_hasta_idle := 3.0
## Animación de Idle del AnimatedSprite2D.
@export var animacion_idle := &"Idle_South"

var _quieto := 0.0
var _en_idle := false


func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	_quieto = 0.0
	_en_idle = false
	jugador.mostrar_pose_quieto()


func fisica(delta: float) -> void:
	if jugador.direccion_input() != Vector2.ZERO:
		_terminar(CAMINAR)
		return
	jugador.velocity = Vector2.ZERO
	jugador.move_and_slide()
	_quieto += delta
	if not _en_idle and _quieto >= segundos_hasta_idle \
			and jugador.sprite.sprite_frames.has_animation(animacion_idle):
		_en_idle = true
		jugador.sprite.play(animacion_idle)


func entrada(evento: InputEvent) -> void:
	if evento.is_action_pressed("accion") and not evento.is_echo():
		_terminar(ATACAR)
