class_name JugadorMuerte
extends JugadorEstado
## Muerte: el personaje se queda quieto y se desvanece. Cuando termina el fundido, el jugador
## emite "murio" (de ahí sale la pantalla de muerte). De aquí no se vuelve.

## Segundos que tarda el sprite en volverse transparente. 0 = sin fundido.
@export_range(0.0, 5.0, 0.05, "suffix:s") var duracion_fundido := 0.6

var _tween: Tween


func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	jugador.velocity = Vector2.ZERO
	jugador.cancelar_retroceso()
	jugador.detener_parpadeo()
	if duracion_fundido <= 0.0:
		_avisar()
		return
	_tween = create_tween()
	_tween.tween_property(jugador.sprite, "modulate:a", 0.0, duracion_fundido)
	_tween.finished.connect(_avisar)


func es_invulnerable() -> bool:
	return true


func _avisar() -> void:
	jugador.murio.emit()
