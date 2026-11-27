class_name ControlesPantalla
extends Label
## Texto de controles en pantalla. Muestra el del modo actual (tetris o mazmorra) y el del
## dispositivo: con un mando conectado, el del mando; si no, el de teclado.
## Es un Label normal: colócalo y dale fuente, color y contorno en el editor. Los textos se
## editan en el inspector. Juego le avisa del modo.

@export_group("Teclado")
@export_multiline var tetris_teclado := "A / D  Mover\nW  Rotar\nQ / E  Rotar\nS  Bajar\nEspacio  Caída rápida\nTab  Guardar pieza\nShift  Ir a la mazmorra\nR  Reiniciar\nP  Pausa"
@export_multiline var mazmorra_teclado := "WASD  Mover\nEspacio  Atacar\nShift  Ir al tetris\nP  Pausa"

@export_group("Mando")
@export_multiline var tetris_mando := "Cruceta / Stick  Mover\nX / B  Rotar\nLB / RB  Rotar\nA  Caída rápida\nPulsar stick izq.  Guardar pieza\nSelect  Ir a la mazmorra\nY  Reiniciar\nStart  Pausa"
@export_multiline var mazmorra_mando := "Cruceta / Stick  Mover\nA  Atacar\nSelect  Ir al tetris\nStart  Pausa"

var _en_tetris := false


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_mando_cambiado)
	_refrescar()


## Cambia entre los controles del tetris y los de la mazmorra.
func mostrar_modo(en_tetris: bool) -> void:
	_en_tetris = en_tetris
	_refrescar()


func _on_mando_cambiado(_dispositivo: int, _conectado: bool) -> void:
	_refrescar()


func _refrescar() -> void:
	var con_mando := not Input.get_connected_joypads().is_empty()
	if _en_tetris:
		text = tetris_mando if con_mando else tetris_teclado
	else:
		text = mazmorra_mando if con_mando else mazmorra_teclado
