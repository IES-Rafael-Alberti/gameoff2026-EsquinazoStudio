class_name EstadoAturdido
extends Estado
## Al recibir daño (y seguir vivo): sale empujado en dirección contraria al golpe, frena y se
## queda quieto e inofensivo hasta acabar la duración. Después vuelve a Perseguir.

## Segundos que dura el aturdimiento.
@export var duracion := 0.4
## Velocidad inicial del empujón (píxeles por segundo). 0 = no retrocede.
@export var fuerza_retroceso := 220.0
## Con cuánta fuerza frena el empujón (píxeles por segundo cada segundo).
@export var deceleracion := 700.0

var _restante := 0.0


func _init() -> void:
	animacion = &"aturdido"


func entrar(_anterior: StringName, datos: Dictionary) -> void:
	_restante = duracion
	var origen: Vector2 = datos.get("origen", Vector2.INF)
	if origen == Vector2.INF or origen.is_equal_approx(enemigo.global_position):
		enemigo.parar()
	else:
		enemigo.velocity = (enemigo.global_position - origen).normalized() * fuerza_retroceso


func fisica(delta: float) -> void:
	enemigo.mover(enemigo.velocity.move_toward(Vector2.ZERO, deceleracion * delta))
	_restante -= delta
	if _restante <= 0.0:
		_terminar(PERSEGUIR if enemigo.maquina.tiene(PERSEGUIR) else INACTIVO)


func salir() -> void:
	enemigo.parar()


func hace_dano_contacto() -> bool:
	return false
