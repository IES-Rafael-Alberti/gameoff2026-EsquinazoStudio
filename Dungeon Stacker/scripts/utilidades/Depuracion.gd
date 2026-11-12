
extends Node2D


func _ready() -> void:
	var escena_actual = get_tree().current_scene

	if escena_actual is Juego or escena_actual is Mazmorra:
		print("Depuración desactivada: juego normal detectado.")
		queue_free()
		return

	print("Modo depuración activado.")

	var entrada_sur = escena_actual.find_child("EntradaSur", true, false)

	if entrada_sur:
		print("Entrada encontrada: ", entrada_sur.get_path())
		print("Entrada global: ", entrada_sur.global_position)

		$Jugador.global_position = entrada_sur.global_position
		print("Jugador global: ", $Jugador.global_position)
	else:
		push_warning("No se ha encontrado EntradaSur.")
