class_name EnemigoPerseguidor
extends Enemigo
## Enemigo que va hacia el jugador. Por defecto en línea recta; los hijos pueden cambiar
## cómo se mueve sobrescribiendo _velocidad_hacia() (el terrestre sigue una ruta).
##
## Cuándo empieza a perseguir se elige con "deteccion":
##   Siempre: desde que carga la sala.
##   Radio:   quieto hasta que el jugador entra en radio_deteccion.

enum Deteccion { SIEMPRE, RADIO }

@export var velocidad := 60.0

@export_group("Detección")
@export var deteccion := Deteccion.SIEMPRE
## Modo Radio: distancia (píxeles) a la que detecta al jugador.
@export var radio_deteccion := 200.0
## Modo Radio: si deja de perseguir cuando el jugador vuelve a salir del radio.
## Desmarcado: una vez que te ha visto, te persigue hasta el final.
@export var perder_al_salir := false

var _persiguiendo := false


func _actuar(_delta: float) -> void:
	var jugador := _jugador()
	if jugador == null:
		velocity = Vector2.ZERO
	else:
		var objetivo := _posicion_de(jugador)
		_actualizar_persecucion(objetivo)
		velocity = _velocidad_hacia(objetivo) if _persiguiendo else Vector2.ZERO
	move_and_slide()


func _actualizar_persecucion(objetivo: Vector2) -> void:
	if deteccion == Deteccion.SIEMPRE:
		_persiguiendo = true
		return
	if global_position.distance_to(objetivo) <= radio_deteccion:
		_persiguiendo = true
	elif perder_al_salir:
		_persiguiendo = false


## Velocidad con la que va hacia el objetivo. Para sobrescribir en los hijos.
func _velocidad_hacia(objetivo: Vector2) -> Vector2:
	return (objetivo - global_position).normalized() * velocidad
