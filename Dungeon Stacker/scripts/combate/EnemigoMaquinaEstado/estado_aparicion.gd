class_name EstadoAparicion
extends Estado
## Al aparecer: si el enemigo ha sido invocado (cofre falso, spawner...) se queda quieto,
## inofensivo e invulnerable bloqueo_invocado segundos (el valor está en Enemigo). Si no, pasa
## a Inactivo al instante. Estado inicial recomendado.

var _restante := 0.0


func _init() -> void:
	animacion = &"aparicion"


func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	enemigo.parar()
	_restante = enemigo.bloqueo_invocado if enemigo.invocado else 0.0
	if _restante <= 0.0:
		_terminar(INACTIVO)


func fisica(delta: float) -> void:
	_restante -= delta
	if _restante <= 0.0:
		_terminar(INACTIVO)


func es_invulnerable() -> bool:
	return true


func hace_dano_contacto() -> bool:
	return false
