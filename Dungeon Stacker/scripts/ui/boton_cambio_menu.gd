extends Button

@export var menu_actual: Control
@export var menu_destino: Control

func _on_pressed():
	menu_actual.hide()
	menu_destino.show()
