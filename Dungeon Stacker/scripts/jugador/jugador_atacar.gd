class_name JugadorAtacar
extends JugadorEstado
## Ataque: reproduce la animación de ataque, hace el golpe pasado retardo_golpe y no se mueve.
## Si el jugador recibe daño mientras ataca, el ataque sigue (con el retroceso aplicado).
## La animación "Attack_<dirección>" no debe estar en bucle: al terminar vuelve a Inactivo.

var _tiempo := 0.0
var _golpe_dado := false


func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	_tiempo = 0.0
	_golpe_dado = false
	jugador.animar("Attack")
	jugador.sprite.animation_finished.connect(_on_animacion_terminada)


func salir() -> void:
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
