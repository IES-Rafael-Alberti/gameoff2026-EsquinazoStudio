extends Node
## SOLO PARA PRUEBAS: simula un combate al entrar en la habitación.
## Borra este nodo cuando haya enemigos de verdad.

@export var duracion := 3.0

@onready var _habitacion := get_parent() as Habitacion


func _ready() -> void:
	if _habitacion.datos != null and _habitacion.datos.resuelta:
		queue_free()
		return
	_habitacion.jugador_entro.connect(_on_jugador_entro)

func _on_jugador_entro() -> void:
	var desafio := Node.new()
	add_child(desafio)
	_habitacion.registrar_desafio(desafio)
	get_tree().create_timer(duracion).timeout.connect(desafio.queue_free)
