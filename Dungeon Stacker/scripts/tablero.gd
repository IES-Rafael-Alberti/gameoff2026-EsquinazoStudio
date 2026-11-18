extends Node

var matriz: Array = []

func crear_tablero() -> void:
	matriz.clear()
	var Configuracion = Tetris.de(self).Configuracion
	for y in range(Configuracion.FILAS):
		var fila: Array = []
		for x in range(Configuracion.COLUMNAS):
			fila.append(null)

		matriz.append(fila)


func comprobar_colision(posicion: Vector2i, forma: Array) -> bool:
	var Configuracion = Tetris.de(self).Configuracion
	for bloque in forma:
		var celda = posicion + bloque
		if celda.x < 0 or celda.x >= Configuracion.COLUMNAS:
			return true

		if celda.y >= Configuracion.FILAS:
			return true

		if celda.y >= 0 and matriz[celda.y][celda.x] != null:
			return true

	return false


## Borra las líneas completas y devuelve cuántas ha borrado.
func comprobar_lineas() -> int:
	var Configuracion = Tetris.de(self).Configuracion
	var y = Configuracion.FILAS - 1
	var lineas := 0

	while y >= 0:
		var linea_completa = true

		for x in range(Configuracion.COLUMNAS):
			if matriz[y][x] == null:
				linea_completa = false
				break

		if linea_completa:
			lineas += 1
			matriz.remove_at(y)

			var nueva_fila: Array = []
			for x in range(Configuracion.COLUMNAS):
				nueva_fila.append(null)

			matriz.push_front(nueva_fila)
		else:
			y -= 1

	return lineas


func fijar_pieza(
	posicion: Vector2i,
	forma: Array,
	textura_fondo: Texture2D,
	categorias: Array,
	bioma: int = Catalogo.Bioma.MEDIEVAL,
	sin_habitacion := false,
	solo_horizontal := false
) -> int:
	var colocadas := 0
	for i in forma.size():
		var celda = posicion + forma[i]

		if celda.y >= 0 and celda.y < matriz.size():
			var categoria: CategoriaSala = null
			if i < categorias.size():
				categoria = categorias[i]

			var nueva := CeldaTablero.new(textura_fondo, categoria, bioma)
			nueva.sin_habitacion = sin_habitacion
			nueva.solo_horizontal = solo_horizontal
			matriz[celda.y][celda.x] = nueva
			colocadas += 1
	return colocadas
