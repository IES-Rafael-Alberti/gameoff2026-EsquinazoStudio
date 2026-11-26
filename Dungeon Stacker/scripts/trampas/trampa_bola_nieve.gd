class_name TrampaBolaNieve
extends Node2D
## Trampa que lanza bolas de nieve cada cierto tiempo: cada bola cae del techo en la posición de
## este nodo y rueda en la dirección elegida hasta caer por un vacío (o chocar con una pared,
## que la hace desaparecer). Empieza a contar cuando el jugador entra en la sala. Las bolas son
## hijas de la sala, así que desaparecen con ella al salir.
##
## Estructura: este nodo (con un Sprite2D hijo opcional que marca la zona donde cae la bola, por
## ejemplo el círculo de los pinchos con la opacidad baja). La escena de la bola es un BolaNieve.
## El diseñador pone un vacío al final del camino.

enum Sentido { ARRIBA, ABAJO, IZQUIERDA, DERECHA }

## Escena de la bola (raíz BolaNieve).
@export var escena_bola: PackedScene
## Hacia dónde ruedan las bolas.
@export var sentido := Sentido.DERECHA

@export_group("Tiempos")
## Segundos desde que el jugador entra en la sala hasta la primera bola.
@export_range(0.0, 60.0, 0.1, "suffix:s") var retraso_inicial := 0.0
## Segundos entre una bola y la siguiente.
@export_range(0.2, 60.0, 0.1, "suffix:s") var intervalo := 3.0

var _espera := 0.0


func _ready() -> void:
	set_physics_process(false)
	var sala := _buscar_habitacion()
	if sala == null:
		_empezar() # escena suelta (pruebas): empieza ya
	else:
		sala.jugador_entro.connect(_empezar, CONNECT_ONE_SHOT)


# Sin awaits: la sala se destruye al salir y un temporizador pendiente seguiría sobre nada.
func _physics_process(delta: float) -> void:
	_espera -= delta
	if _espera > 0.0:
		return
	_espera += intervalo
	_lanzar()


func _empezar() -> void:
	_espera = retraso_inicial
	set_physics_process(true)


func _lanzar() -> void:
	if escena_bola == null:
		push_warning("La trampa %s no tiene escena_bola." % name)
		set_physics_process(false)
		return
	var bola := escena_bola.instantiate() as BolaNieve
	if bola == null:
		push_error("La escena de la trampa %s debe tener un BolaNieve como raíz." % name)
		set_physics_process(false)
		return
	bola.direccion = _vector_del_sentido()
	add_sibling(bola)
	bola.global_position = global_position


func _vector_del_sentido() -> Vector2:
	match sentido:
		Sentido.ARRIBA:
			return Vector2.UP
		Sentido.ABAJO:
			return Vector2.DOWN
		Sentido.IZQUIERDA:
			return Vector2.LEFT
	return Vector2.RIGHT


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
