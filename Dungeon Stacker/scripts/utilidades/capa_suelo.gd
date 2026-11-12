class_name CapaSuelo
extends TileMapLayer
## TileMapLayer de las salas. Además de pintar el suelo, permite quitar la malla de
## navegación de casillas concretas mientras la sala está cargada (trampas fijas, cerraduras...),
## para que los enemigos que andan no planifiquen rutas por ellas.
## No toca el TileSet: el cambio vale solo para esta sala cargada.

# Casillas (coordenadas de la capa) sin malla de navegación.
var _bloqueadas := {}


## Quita la malla de navegación de esas casillas.
func bloquear(celdas: Array[Vector2i]) -> void:
	var hubo_cambio := false
	for celda in celdas:
		if not _bloqueadas.has(celda):
			_bloqueadas[celda] = true
			hubo_cambio = true
	if hubo_cambio:
		notify_runtime_tile_data_update()


func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return _bloqueadas.has(coords)


# Solo se llama para las casillas en las que _use_tile_data_runtime_update devuelve true.
func _tile_data_runtime_update(_coords: Vector2i, datos: TileData) -> void:
	datos.set_navigation_polygon(0, null)
