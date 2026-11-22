class_name ReceptorElectrico
extends Node2D
## Receptor de la red eléctrica: reacciona cuando la corriente le llega o se le corta. Se coloca
## sobre una casilla de cable (el centro del nodo, dentro de la casilla) y se arrastra a la lista
## "receptores" de la CapaElectrica. Los destinos (láseres, cambiadores...) no saben nada de
## electricidad: solo necesitan los métodos encender(), apagar() y alternar().

enum Accion { NADA, ALTERNAR, ENCENDER, APAGAR }

## Se emite cuando la luz llega (true) o se corta (false) en la casilla del receptor.
signal corriente_cambiada(hay_corriente: bool)

@export_group("Efecto")
## Qué hace a los destinos cuando la corriente llega a este receptor.
@export var al_llegar_corriente := Accion.NADA
## Qué hace a los destinos cuando la corriente se corta.
@export var al_cortarse_corriente := Accion.NADA
## Láseres, cambiadores de baldosas... a los que afecta.
@export var destinos: Array[Node] = []


## Lo llama la CapaElectrica.
func recibir_corriente(hay_corriente: bool) -> void:
	corriente_cambiada.emit(hay_corriente)
	var accion := al_llegar_corriente if hay_corriente else al_cortarse_corriente
	for destino in destinos:
		if destino == null:
			continue
		match accion:
			Accion.ALTERNAR:
				if destino.has_method("alternar"):
					destino.alternar()
			Accion.ENCENDER:
				if destino.has_method("encender"):
					destino.encender()
			Accion.APAGAR:
				if destino.has_method("apagar"):
					destino.apagar()
