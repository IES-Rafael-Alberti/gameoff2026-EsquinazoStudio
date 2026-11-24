extends Control
## Opciones de volumen. Raíz de opciones.tscn. Reutilizable en el menú de pausa.
## Todo se conecta por señales desde el editor (ver la lista del mensaje); aquí solo está la lógica.

signal cerrado


func _on_master_value_changed(valor: float) -> void:
	_poner_volumen(&"Master", valor)


func _on_music_value_changed(valor: float) -> void:
	_poner_volumen(&"Music", valor)


func _on_sfx_value_changed(valor: float) -> void:
	_poner_volumen(&"SFX", valor)


func _on_volver_pressed() -> void:
	visible = false
	cerrado.emit()


func _poner_volumen(nombre_bus: StringName, valor: float) -> void:
	var bus := AudioServer.get_bus_index(nombre_bus)
	if bus == -1:
		push_warning("Opciones: no existe el bus %s." % nombre_bus)
		return
	AudioServer.set_bus_mute(bus, valor <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(valor, 0.001)))
