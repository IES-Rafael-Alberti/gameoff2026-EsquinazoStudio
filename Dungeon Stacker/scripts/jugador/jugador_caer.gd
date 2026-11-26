class_name JugadorCaer
extends JugadorEstado
## Caída al vacío: el sprite se encoge con la animación "caer" (AnimationPlayer AnimacionCaida),
## el jugador recibe daño y reaparece en el destino con invulnerabilidad. Sin control mientras
## dura. Al acabar emite caida_terminada del jugador (quien lo llamó espera esa señal).

var _dano := 0
var _destino := Vector2.ZERO
## Escala del sprite al empezar a caer (la del jugador, no necesariamente 1).
var _escala_sprite := Vector2.ONE


func entrar(_anterior: StringName, datos: Dictionary) -> void:
	_dano = datos.get("dano", 0)
	_destino = datos.get("destino", jugador.position)
	_escala_sprite = jugador.sprite.scale
	jugador.velocity = Vector2.ZERO
	jugador.cancelar_retroceso()
	jugador.animacion_caida.play("caer")
	jugador.animacion_caida.animation_finished.connect(_on_caida_terminada, CONNECT_ONE_SHOT)


func es_invulnerable() -> bool:
	return true


func _on_caida_terminada(_nombre: StringName) -> void:
	# Si ya no es el estado activo (murió, por ejemplo), solo avisa de que terminó.
	if jugador.maquina.actual != self:
		jugador.caida_terminada.emit()
		return
	# El daño del vacío no lo frena la invulnerabilidad anterior.
	jugador.vida.recibir_dano(_dano)
	if jugador.vida.esta_viva():
		jugador.sprite.scale = _escala_sprite
		jugador.sprite.rotation = 0.0
		jugador.position = _destino
		jugador.iniciar_invulnerabilidad()
		_terminar(INACTIVO)
	jugador.caida_terminada.emit()
