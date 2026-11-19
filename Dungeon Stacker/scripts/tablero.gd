
extends Node

var matriz: Array = []
## Posiciones con barrera ACTIVA -> nombre de su grupo.
var _barreras: Dictionary = {}


func crear_tablero() -> void:
	matriz.clear()
	var Configuracion = Tetris.de(self).Configuracion
	for y in range(Configuracion.FILAS):
		var fila: Array = []
		for x in range(Configuracion.COLUMNAS):
			fila.append(null)

		matriz.append(fila)

	_colocar_casillas_especiales()
	_colocar_barreras()


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


## Pone en el tablero las casillas bloqueadas y las fijas del nivel.
func _colocar_casillas_especiales() -> void:
	var Configuracion = Tetris.de(self).Configuracion
	for pos in Configuracion.CASILLAS_BLOQUEADAS:
		if not _dentro(pos):
			push_warning("Casilla bloqueada fuera del tablero: %s" % pos)
			continue
		var bloqueada := CeldaTablero.new(Configuracion.TEXTURA_BLOQUEADA)
		bloqueada.bloqueada = true
		bloqueada.sin_habitacion = true
		matriz[pos.y][pos.x] = bloqueada
	for fija in Configuracion.CASILLAS_FIJAS:
		if fija == null:
			continue
		if not _dentro(fija.posicion):
			push_warning("Casilla fija fuera del tablero: %s" % fija.posicion)
			continue
		if matriz[fija.posicion.y][fija.posicion.x] != null:
			push_warning("Casilla fija en %s: ya hay otra casilla especial; se ignora." % fija.posicion)
			continue
		var celda := CeldaTablero.new(Configuracion.TEXTURA_FIJA)
		celda.fija = true
		celda.escena_sala = fija.escena
		matriz[fija.posicion.y][fija.posicion.x] = celda


## Registra las posiciones barrera de todos los grupos del nivel.
func _colocar_barreras() -> void:
	_barreras.clear()
	var Configuracion = Tetris.de(self).Configuracion
	for grupo in Configuracion.CASILLAS_BARRERA:
		if grupo == null:
			continue
		for pos in grupo.posiciones:
			if not _dentro(pos):
				push_warning("Barrera '%s' fuera del tablero: %s" % [grupo.nombre, pos])
			elif _es_inmovil(pos.x, pos.y):
				push_warning("Barrera '%s' en %s: ya hay una casilla fija o bloqueada; se ignora." % [grupo.nombre, pos])
			elif _barreras.has(pos):
				push_warning("Barrera '%s' en %s: la posición ya es de otro grupo; se ignora." % [grupo.nombre, pos])
			else:
				_barreras[pos] = grupo.nombre


## Posiciones con barrera activa (para dibujarlas).
func posiciones_barrera() -> Array[Vector2i]:
	var posiciones: Array[Vector2i] = []
	for pos in _barreras:
		posiciones.append(pos)
	return posiciones


## Apaga un grupo de barreras: sus casillas ocupadas recuperan su sala. Devuelve false si no
## había ninguna posición activa con ese nombre.
func desactivar_barrera(grupo: StringName) -> bool:
	var quitadas: Array[Vector2i] = []
	for pos in _barreras:
		if _barreras[pos] == grupo:
			quitadas.append(pos)
	for pos in quitadas:
		_barreras.erase(pos)
	_aplicar_barreras()
	return not quitadas.is_empty()


## Las casillas colocadas sobre una barrera activa no son sala; fuera de ella, vuelven a lo
## que eran. Se recalcula por posición, así sigue bien aunque la casilla caiga al borrar líneas.
func _aplicar_barreras() -> void:
	for y in range(matriz.size()):
		for x in range(matriz[y].size()):
			var celda = matriz[y][x]
			if celda == null or celda.es_inmovil():
				continue
			celda.sin_habitacion = celda.sin_habitacion_original or _barreras.has(Vector2i(x, y))


func _dentro(pos: Vector2i) -> bool:
	var Configuracion = Tetris.de(self).Configuracion
	return pos.x >= 0 and pos.x < Configuracion.COLUMNAS and pos.y >= 0 and pos.y < Configuracion.FILAS


func _es_inmovil(x: int, y: int) -> bool:
	var celda = matriz[y][x]
	return celda != null and celda.es_inmovil()


## Una fila está completa si todas sus casillas están ocupadas Y al menos una se puede borrar
## (una fila hecha solo de casillas fijas o bloqueadas no cuenta).
func _linea_completa(y: int) -> bool:
	var hay_borrable := false
	for x in range(matriz[y].size()):
		var celda = matriz[y][x]
		if celda == null:
			return false
		if not celda.es_inmovil():
			hay_borrable = true
	return hay_borrable


## Borra de la fila y las casillas que no son inmóviles. Las inmóviles se quedan donde están.
## En cada columna, lo que hay encima baja una casilla, hasta toparse con una inmóvil: lo que
## está apoyado sobre una casilla inmóvil no baja.
func _borrar_linea(y: int) -> void:
	for x in range(matriz[y].size()):
		if _es_inmovil(x, y):
			continue
		var r := y
		while r > 0 and not _es_inmovil(x, r - 1):
			matriz[r][x] = matriz[r - 1][x]
			r -= 1
		matriz[r][x] = null


## Borra las líneas completas y devuelve cuántas ha borrado.
func comprobar_lineas() -> int:
	var Configuracion = Tetris.de(self).Configuracion
	var y = Configuracion.FILAS - 1
	var lineas := 0

	while y >= 0:
		if _linea_completa(y):
			lineas += 1
			_borrar_linea(y)
		else:
			y -= 1

	_aplicar_barreras()
	return lineas


func fijar_pieza(
	posicion: Vector2i,
	forma: Array,
	textura_fondo: Texture2D,
	categorias: Array,
	bioma: int = Catalogo.Bioma.MEDIEVAL,
	sin_habitacion := false,
	solo_horizontal := false,
	escenas: Array = []
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
			nueva.sin_habitacion_original = sin_habitacion
			nueva.solo_horizontal = solo_horizontal
			if i < escenas.size():
				nueva.escena_sala = escenas[i]
			matriz[celda.y][celda.x] = nueva
			colocadas += 1
	_aplicar_barreras()
	return colocadas