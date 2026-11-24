class_name PinchosHielo
extends Peligro
## Pinchos estáticos sobre hielo: dañan al tocarlos (son un Peligro, como PinchosEstaticos)
## y además la casilla en la que están cuenta como hielo, así que el jugador resbala por ellos.
## No hace falta pintar baldosa de hielo debajo. Son atravesables, como el resto de Peligros.


func _ready() -> void:
	super._ready()
	# La sala lee este grupo al cargarse para saber qué casillas son hielo.
	add_to_group("hielo_objeto")
