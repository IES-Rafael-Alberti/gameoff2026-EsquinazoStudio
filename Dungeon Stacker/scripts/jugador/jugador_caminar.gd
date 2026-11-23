class_name JugadorCaminar
extends JugadorEstado
## Se mueve con el input, anima la caminata y empuja las cajas contra las que avanza.


func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	jugador.animar("Walk")


func fisica(delta: float) -> void:
	var direccion := jugador.direccion_input()
	if direccion == Vector2.ZERO:
		_terminar(INACTIVO)
		return
	jugador.actualizar_direccion(direccion)
	jugador.animar("Walk")
	jugador.velocity = direccion * jugador.speed
	jugador.move_and_slide()
	jugador.empujar_cajas(direccion, delta)


func entrada(evento: InputEvent) -> void:
	if evento.is_action_pressed("accion") and not evento.is_echo():
		_terminar(ATACAR)
