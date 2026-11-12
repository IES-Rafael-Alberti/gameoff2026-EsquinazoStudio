class_name PantallaMuerte
extends CanvasLayer
## Pantalla de "has muerto". Se muestra con el juego pausado y avisa cuando se pide reiniciar.

signal reinicio_pedido

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS # sigue funcionando con el juego en pausa
	visible = false

	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.7)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var texto := Label.new()
	texto.text = "HAS MUERTO\n\nPulsa R o Enter para reiniciar el nivel"
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.add_theme_font_size_override("font_size", 48)
	add_child(texto)

func mostrar() -> void:
	visible = true

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_R, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		reinicio_pedido.emit()
