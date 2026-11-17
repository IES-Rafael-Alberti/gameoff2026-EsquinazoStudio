extends CanvasLayer

@export var forzar_visible := false

func _ready() -> void:
	var mostrar := forzar_visible or DisplayServer.is_touchscreen_available()
	visible = mostrar
	if forzar_visible:
		for boton in find_children("*", "TouchScreenButton", true, false):
			boton.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
