extends Control
## Menú principal. Raíz de menu_principal.tscn. Todo se conecta por señales desde el editor.

@export var panel_principal: Control
@export var opciones: Control
@export var niveles: Control
@export var boton_continuar: Button
@export var boton_salir: Button

func _ready() -> void:
	Musica.reproducir_menu()
	# En la versión web quit() no cierra la pestaña: el botón no tiene sentido.
	if OS.has_feature("web"):
		boton_salir.visible = false
	_mostrar_principal()

func _mostrar_principal() -> void:
	opciones.visible = false
	niveles.visible = false
	panel_principal.visible = true
	boton_continuar.disabled = not Partida.puede_continuar()

## Señal "cerrado" de Opciones y de Niveles.
func _on_submenu_cerrado() -> void:
	_mostrar_principal()

func _on_play_button_pressed() -> void:
	Partida.jugar_nivel(0) # START: siempre el tutorial

func _on_continue_button_pressed() -> void:
	Partida.continuar()

func _on_level_button_pressed() -> void:
	panel_principal.visible = false
	niveles.mostrar()

func _on_options_button_pressed() -> void:
	panel_principal.visible = false
	opciones.visible = true

func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_opciones_cerrado() -> void:
	pass # Replace with function body.


func _on_niveles_cerrado() -> void:
	pass # Replace with function body.
