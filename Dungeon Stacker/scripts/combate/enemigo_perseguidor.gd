class_name EnemigoPerseguidor
extends Enemigo
## Enemigo que va directo hacia el jugador.

@export var velocidad := 60.0


func _actuar(_delta: float) -> void:
	var jugador := _jugador()
	if jugador == null:
		velocity = Vector2.ZERO
	else:
		velocity = (_posicion_de(jugador) - global_position).normalized() * velocidad
	move_and_slide()
