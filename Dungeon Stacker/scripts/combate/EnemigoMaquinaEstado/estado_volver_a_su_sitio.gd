class_name EstadoVolverASuSitio
extends Estado
## Vuelve a la posición en la que empezó el enemigo y, al llegar, pasa a Inactivo. Se llega
## aquí desde Perseguir cuando perder_al_salir está marcado y el jugador sale del radio.

## Distancia (píxeles) a la que da por llegado.
@export var tolerancia := 6.0
## Si, mientras vuelve, vuelve a perseguir al jugador en cuanto lo detecta de nuevo.
@export var reaccionar_al_jugador := false


func _init() -> void:
	animacion = &"volver"


func fisica(_delta: float) -> void:
	if reaccionar_al_jugador and enemigo.jugador_detectado():
		_terminar(PERSEGUIR)
		return
	if enemigo.global_position.distance_to(enemigo.posicion_inicial) <= tolerancia:
		_terminar(INACTIVO)
		return
	enemigo.mover_hacia(enemigo.posicion_inicial, enemigo.velocidad)
