class_name JugadorCaminar
extends JugadorEstado
## Se mueve con el input, anima la caminata y empuja las cajas contra las que avanza.
## Si pisa hielo mientras se mueve, pasa a Resbalar.


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
	# Pisar hielo en movimiento arranca el deslizamiento en esa dirección.
	if jugador.en_hielo() and jugador.get_real_velocity().length() > 1.0:
		_terminar(RESBALAR, {"direccion": direccion})


func entrada(evento: InputEvent) -> void:
	if evento.is_action_pressed("accion") and not evento.is_echo():
		_terminar(ATACAR)
