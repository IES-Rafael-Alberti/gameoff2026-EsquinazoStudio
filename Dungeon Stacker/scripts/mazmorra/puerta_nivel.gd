class_name PuertaNivel
extends Area2D
## Puerta de los vestíbulos que termina el nivel al tocarla. Escena propia (puerta_nivel.tscn):
## Area2D en la raíz con un Sprite2D (el placeholder) y un CollisionShape2D. En el inspector,
## la máscara de colisión debe incluir la capa del jugador, y la señal body_entered de la raíz
## se conecta a _on_body_entered.
## El vestíbulo inferior la coloca también (decorativa, con activa = false); solo funciona
## la del vestíbulo superior.

## El jugador la ha tocado estando activa.
signal tocada

## Si se desactiva no reacciona al jugador. Lo pone el vestíbulo que la instancia.
@export var activa := true:
	set(valor):
		activa = valor
		# Diferido: también se cambia desde la señal body_entered, donde el motor lo bloquea.
		set_deferred(&"monitoring", valor)


func _on_body_entered(cuerpo: Node2D) -> void:
	if not activa or not cuerpo.is_in_group("jugador"):
		return
	activa = false # una sola vez
	# Diferido: quien la escucha cambia de escena, y eso no se puede hacer en un callback de física.
	tocada.emit.call_deferred()
