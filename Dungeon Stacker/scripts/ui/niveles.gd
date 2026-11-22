extends Control
## Selección de nivel. Raíz de niveles.tscn. Todo se conecta por señales desde el editor.

signal cerrado

## Los botones de nivel EN ORDEN (tutorial, 1, 2, 3): solo para desactivar los bloqueados.
@export var botones_nivel: Array[Button] = []


## Muestra la pantalla con los niveles al día (se llama cada vez que se abre).
func mostrar() -> void:
	for i in botones_nivel.size():
		botones_nivel[i].disabled = not Partida.nivel_disponible(i)
	visible = true


func _on_tutorial_pressed() -> void:
	Partida.jugar_nivel(0)


func _on_nivel_1_pressed() -> void:
	Partida.jugar_nivel(1)


func _on_nivel_2_pressed() -> void:
	Partida.jugar_nivel(2)


func _on_nivel_3_pressed() -> void:
	Partida.jugar_nivel(3)


func _on_volver_pressed() -> void:
	visible = false
	cerrado.emit()
