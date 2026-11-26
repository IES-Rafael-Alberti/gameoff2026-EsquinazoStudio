class_name PantallaMuerte
extends CanvasLayer
## Pantalla de "has muerto". Escena propia que se instancia dentro de juego.tscn, encima del
## juego. Se muestra con el árbol en pausa y pide reiniciar el nivel con el botón o con casi
## cualquier entrada (tecla, clic o toque en pantalla, botón del mando), menos la de pausa.
##
## En el inspector de la raíz: Layer alto (100), Process > Mode = Always (tiene que funcionar con
## el árbol en pausa) y Visible = apagado. El botón conecta su señal pressed a
## _on_reiniciar_pressed, y reinicio_pedido se conecta a Juego.reiniciar_nivel.

## Se pide reiniciar el nivel. Conéctala a Juego.reiniciar_nivel.
signal reinicio_pedido

## Segundos tras mostrarse en los que se ignoran las teclas, para que el jugador no reinicie sin
## querer pulsando algo en el momento de morir. El botón funciona siempre. 0 = sin retardo.
@export_range(0.0, 3.0, 0.1, "suffix:s") var retardo_entrada := 0.7

var _acepta_desde_ms := 0
var _pedido := false


func mostrar() -> void:
	_pedido = false
	_acepta_desde_ms = Time.get_ticks_msec() + int(retardo_entrada * 1000.0)
	visible = true


func _input(event: InputEvent) -> void:
	if not visible or _pedido or Time.get_ticks_msec() < _acepta_desde_ms:
		return
	if event.is_action("pausa") or not _es_pulsacion(event):
		return
	get_viewport().set_input_as_handled()
	_pedir_reinicio()


## Conecta aquí la señal pressed del botón de la escena.
func _on_reiniciar_pressed() -> void:
	_pedir_reinicio()


func _pedir_reinicio() -> void:
	if _pedido:
		return
	_pedido = true
	reinicio_pedido.emit()


## Teclas, botones del mando, clics y toques (solo al pulsar, no al soltar ni al repetirse).
func _es_pulsacion(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton or event is InputEventMouseButton \
			or event is InputEventScreenTouch:
		return event.pressed
	return false
