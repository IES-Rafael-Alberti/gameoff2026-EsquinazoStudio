extends Node2D
## Dibuja las casillas fijas del tablero. Al completar líneas, anima el cambio solo en lo visual:
## las casillas de la línea se destruyen de izquierda a derecha y, tras una pequeña espera, todo
## lo que había encima baja en bloque. El tablero lógico ya está actualizado desde el principio.

const ESCENA_CUADRADO = preload("res://scenes/tetris/cuadrado.tscn")

# Tiempos de la animación de línea (segundos). Iguales siempre; se cambian aquí.
## Pausa entre que se destruye una columna y la siguiente.
const RETARDO_COLUMNA := 0.03
## Lo que tarda en ponerse blanca una casilla antes de encogerse.
const DURACION_DESTELLO := 0.05
## Lo que tarda en encogerse hasta desaparecer.
const DURACION_DESTRUIR := 0.12
## Espera desde que se destruye la última casilla hasta que empieza la caída.
const ESPERA_CAIDA := 0.08
## Lo que tarda en bajar lo de arriba.
const DURACION_CAIDA := 0.2
## Brillo del destello (>1 = más blanco que el original).
const BRILLO_DESTELLO := 2.5

var tablero: Array = []
var _cuadrados: Array = []
var _tween_lineas: Tween


## Copia de las filas del tablero tal como está ahora (las casillas son las mismas, solo se copia
## su colocación). Sirve para comparar el antes y el después de borrar líneas.
func instantanea(origen: Array) -> Array:
	var copia: Array = []
	for fila in origen:
		copia.append(fila.duplicate())
	return copia


func actualizar_tablero(nuevo_tablero: Array) -> void:
	_cancelar_animacion()
	tablero = nuevo_tablero
	_dibujar(nuevo_tablero)


## Anima el paso de "antes" (con la línea completa) a "despues" (ya sin ella).
func animar_lineas(antes: Array, despues: Array) -> void:
	_cancelar_animacion()
	tablero = despues
	var cuadrado_de := _dibujar(antes)
	var pos_antes := _posiciones(antes)
	var pos_despues := _posiciones(despues)
	var tam: int = Tetris.de(self).Configuracion.TAM_CELDA
	var columnas: int = Tetris.de(self).Configuracion.COLUMNAS
	var inicio_caida := (columnas - 1) * RETARDO_COLUMNA + DURACION_DESTELLO \
			+ DURACION_DESTRUIR + ESPERA_CAIDA

	_tween_lineas = create_tween().set_parallel(true)
	for celda in pos_antes:
		var cuadrado: Cuadrado = cuadrado_de[celda]
		var origen: Vector2i = pos_antes[celda]
		if not pos_despues.has(celda):
			var espera: float = origen.x * RETARDO_COLUMNA
			_tween_lineas.tween_property(cuadrado, "modulate", Color(BRILLO_DESTELLO, BRILLO_DESTELLO, BRILLO_DESTELLO), DURACION_DESTELLO).set_delay(espera)
			_tween_lineas.tween_method(_encoger.bind(cuadrado, Vector2(origen * tam), tam), 1.0, 0.0, DURACION_DESTRUIR).set_delay(espera + DURACION_DESTELLO)
			_tween_lineas.tween_callback(cuadrado.hide).set_delay(espera + DURACION_DESTELLO + DURACION_DESTRUIR)
		elif pos_despues[celda] != origen:
			_tween_lineas.tween_property(cuadrado, "position", Vector2(pos_despues[celda] * tam), DURACION_CAIDA) \
					.set_delay(inicio_caida).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween_lineas.finished.connect(_terminar_animacion)


## Encoge la casilla hacia su centro (los sprites del cuadrado cuelgan de su esquina).
func _encoger(escala: float, cuadrado: Cuadrado, origen: Vector2, tam: int) -> void:
	cuadrado.scale = Vector2.ONE * escala
	cuadrado.position = origen + Vector2.ONE * tam * (1.0 - escala) * 0.5


func _terminar_animacion() -> void:
	_tween_lineas = null
	_dibujar(tablero)


func _cancelar_animacion() -> void:
	if _tween_lineas != null:
		_tween_lineas.kill()
		_tween_lineas = null


## Casilla -> posición (columna, fila) en ese tablero.
func _posiciones(origen: Array) -> Dictionary:
	var resultado := {}
	for y in origen.size():
		for x in origen[y].size():
			if origen[y][x] != null:
				resultado[origen[y][x]] = Vector2i(x, y)
	return resultado


## Pinta el tablero dado y devuelve casilla -> cuadrado que la dibuja.
func _dibujar(origen: Array) -> Dictionary:
	var Configuracion = Tetris.de(self).Configuracion
	var posiciones: Array = []
	var celdas: Array = []
	if origen.size() >= Configuracion.FILAS:
		for y in range(Configuracion.FILAS):
			for x in range(Configuracion.COLUMNAS):
				var celda = origen[y][x]
				if celda != null:
					posiciones.append(Vector2i(x, y))
					celdas.append(celda)

	_asegurar_cuadrados(posiciones.size())

	var cuadrado_de := {}
	for i in _cuadrados.size():
		var cuadrado = _cuadrados[i]

		if i >= posiciones.size():
			cuadrado.visible = false
			continue

		var celda = celdas[i]
		cuadrado.visible = true
		cuadrado.scale = Vector2.ONE
		cuadrado.modulate = Color.WHITE
		cuadrado.configurar(celda.textura_fondo, Catalogo.marco_bioma(celda.bioma), celda.categoria, null, celda.solo_horizontal)
		cuadrado.poner_en_celda(posiciones[i])
		cuadrado_de[celda] = cuadrado
	return cuadrado_de


func _asegurar_cuadrados(cantidad: int) -> void:
	var Configuracion = Tetris.de(self).Configuracion
	while _cuadrados.size() < cantidad:
		var cuadrado = ESCENA_CUADRADO.instantiate()
		cuadrado.tamano = Configuracion.TAM_CELDA
		add_child(cuadrado)
		_cuadrados.append(cuadrado)
