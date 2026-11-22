class_name MenuPausa
extends CanvasLayer
## Menú de pausa. Escena propia que se instancia dentro de juego.tscn, encima del juego.
## En el inspector de la raíz: Process > Mode = Always (tiene que funcionar con el árbol en
## pausa) y Visible = apagado. Todo se conecta por señales desde el editor.

## Se pide reiniciar el nivel. Conéctala a Juego.reiniciar_nivel.
signal reinicio_pedido

## El panel con los botones de la pausa (Reanudar, Reiniciar, Opciones, Menú principal).
@export var panel_principal: Control
## La instancia de opciones.tscn dentro de esta escena.
@export var opciones: Control

# Si el árbol ya estaba en pausa al abrir (pantalla de muerte), al cerrar se queda como estaba.
var _arbol_estaba_pausado := false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		if visible:
			cerrar()
		else:
			abrir()

func abrir() -> void:
	_arbol_estaba_pausado = get_tree().paused
	get_tree().paused = true
	Musica.atenuar_pausa(true)
	_mostrar_principal()
	visible = true

func cerrar() -> void:
	visible = false
	get_tree().paused = _arbol_estaba_pausado
	Musica.atenuar_pausa(false)

func _mostrar_principal() -> void:
	opciones.visible = false
	panel_principal.visible = true

func _on_reanudar_pressed() -> void:
	cerrar()

func _on_reiniciar_pressed() -> void:
	Musica.atenuar_pausa(false)
	reinicio_pedido.emit()

func _on_opciones_pressed() -> void:
	panel_principal.visible = false
	opciones.visible = true

## Señal "cerrado" de la instancia de Opciones.
func _on_opciones_cerrado() -> void:
	_mostrar_principal()

func _on_menu_principal_pressed() -> void:
	Musica.atenuar_pausa(false)
	Partida.volver_al_menu()
