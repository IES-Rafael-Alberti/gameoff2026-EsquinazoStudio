class_name PuzleSecuencia
extends PuzleBotones
## Las placas hay que activarlas en el orden en que aparecen como hijas en el árbol.
## Si se activa una fuera de orden, tras un breve retardo todas se levantan y se empieza de nuevo.
## Las placas deben tener marcado "Se Queda Activa" para que se vea el avance.

## Segundos que se ve la placa equivocada hundida antes de reiniciar la secuencia.
@export var retardo_fallo := 0.5

var _fallando := false


## Se llama cada vez que se activa una placa. Las activas deben ser siempre las primeras, en orden.
func _comprobar() -> void:
	if _placas.is_empty() or _fallando:
		return
	var activas := 0
	for placa in _placas:
		if placa.activa:
			activas += 1
	for i in _placas.size():
		if _placas[i].activa != (i < activas):
			_fallar()
			return
	if activas == _placas.size():
		resolver()


## Orden incorrecto: se deja ver el fallo un momento y luego se reinicia todo.
func _fallar() -> void:
	_fallando = true
	await get_tree().create_timer(retardo_fallo).timeout
	if not is_inside_tree():
		return
	_fallando = false
	_al_reiniciar()
