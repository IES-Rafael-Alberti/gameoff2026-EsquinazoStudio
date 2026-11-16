class_name EstadoInactivo
extends Estado
## Quieto esperando. En cuanto el enemigo detecta al jugador (ver "deteccion" en
## EnemigoEstados) pasa a Perseguir.


func _init() -> void:
	animacion = &"inactivo"


func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	enemigo.parar()


func fisica(_delta: float) -> void:
	if enemigo.jugador_detectado():
		_terminar(PERSEGUIR)
