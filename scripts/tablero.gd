extends Node

const Configuracion = preload("res://scripts/configuracion.gd")

var matriz: Array = []

func crear_tablero() -> void:
	matriz.clear()

	for y in range(Configuracion.FILAS):
		var fila: Array = []

		for x in range(Configuracion.COLUMNAS):
			fila.append(0)

		matriz.append(fila)


func comprobar_colision(posicion: Vector2i, forma: Array) -> bool:
	for bloque in forma:
		var celda = posicion + bloque

		# Comprobar paredes
		if celda.x < 0 or celda.x >= Configuracion.COLUMNAS:
			return true

		# Comprobar suelo
		if celda.y >= Configuracion.FILAS:
			return true

		# Comprobar bloques fijados
		if celda.y >= 0 and typeof(matriz[celda.y][celda.x]) == TYPE_COLOR:
			return true

	return false


func comprobar_lineas() -> void:
	var y = Configuracion.FILAS - 1

	while y >= 0:
		var linea_completa = true

		for x in range(Configuracion.COLUMNAS):
			if typeof(matriz[y][x]) != TYPE_COLOR:
				linea_completa = false
				break

		if linea_completa:
			matriz.remove_at(y)

			var nueva_fila: Array = []
			for x in range(Configuracion.COLUMNAS):
				nueva_fila.append(0)

			matriz.push_front(nueva_fila)
		else:
			y -= 1

func fijar_pieza(posicion: Vector2i, forma: Array, color: Color) -> void:
	for bloque in forma:
		var celda = posicion + bloque
		if celda.y >= 0:
			matriz[celda.y][celda.x] = color
