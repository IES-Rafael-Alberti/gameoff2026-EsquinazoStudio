extends Node
# Todas las piezas de Tetris

const FORMAS = {
	"I": [
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(3, 1)
	],

	"O": [
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(1, 1),
		Vector2i(2, 1)
	],
	"T": [
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1)
	],

	"S": [
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(0, 1),
		Vector2i(1, 1)
	],

	"Z": [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(2, 1)
	],

	"J": [
		Vector2i(0, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1)
	],

	"L": [
		Vector2i(2, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1)
	],
	"TT": [
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(2, 0),
		Vector2i(2, 2)
	],
	"H": [
		Vector2i(0, 0),
		Vector2i(0, 1),
		Vector2i(0, 2),
		Vector2i(1, 1),
		Vector2i(2, 0),
		Vector2i(2, 1),
		Vector2i(2, 2)
	],
	"X": [
		Vector2i(0, 0),
		Vector2i(0, 2),
		Vector2i(1, 1),
		Vector2i(2, 0),
		Vector2i(2, 2)
	],
	"P": [
		Vector2i(0, 0)
	],
	"+": [
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(1, 0),
		Vector2i(1, 2)
	],
	"-": [
		Vector2i(0, 0),
		Vector2i(0, 2),
		Vector2i(2, 0),
		Vector2i(2, 2)
	],
	"C": [
		Vector2i(0, 0),
		Vector2i(0, 2),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(1, 2)
	]
}

const TEXTURAS_COLOR = {
	"I": preload("res://assets/sprites/piezas/Pieza celeste.png"),
	"O": preload("res://assets/sprites/piezas/Pieza amarilla.png"),
	"T": preload("res://assets/sprites/piezas/Pieza morada.png"),
	"S": preload("res://assets/sprites/piezas/Pieza verde.png"),
	"Z": preload("res://assets/sprites/piezas/Pieza roja.png"),
	"J": preload("res://assets/sprites/piezas/Pieza azul.png"),
	"L": preload("res://assets/sprites/piezas/Pieza naranja.png"),
	"TT": preload("res://assets/sprites/piezas/Pieza marron.png"),
	"H": preload("res://assets/sprites/piezas/Pieza gris.png"),
	"X": preload("res://assets/sprites/piezas/Pieza rosa.png"),
	"P": preload("res://assets/sprites/piezas/Pieza lima.png"),
	"+": preload("res://assets/sprites/piezas/Pieza turquesa.png"),
	"-": preload("res://assets/sprites/piezas/Pieza verde pistacho.png"),
	"C": preload("res://assets/sprites/piezas/Pieza gris oscuro.png")
}

var _avisado_sin_categorias := false


func _ready() -> void:
	# Las casillas de PIEZAS_NIVEL siguen el orden de esta lista: deben coincidir con FORMAS.
	if FORMAS.keys() != Configuracion_Tablero.NOMBRES_PIEZAS:
		push_error("Configuracion_Tablero.NOMBRES_PIEZAS no coincide con Piezas.FORMAS: las casillas de PIEZAS_NIVEL no corresponden a las piezas.")


# Obtener una pieza aleatoria entre las que permite el nivel
func pieza_aleatoria() -> String:
	var config = Tetris.de(self).Configuracion
	if config != null:
		var permitidas: Array[String] = config.piezas_permitidas()
		if not permitidas.is_empty():
			return permitidas.pick_random()
		push_warning("PIEZAS_NIVEL no tiene ninguna pieza marcada; usando todas.")
	return FORMAS.keys().pick_random()

## Cuántas piezas se han generado en este nivel (la 1ª pieza es el turno 1).
var _generadas := 0

## Vuelve a empezar la cuenta de turnos (al reiniciar el nivel).
func reiniciar_secuencia() -> void:
	_generadas = 0

func generar_pieza() -> PiezaGenerada:
	_generadas += 1
	var escogida := _escogida_para_turno(_generadas)
	if escogida == null:
		escogida = _escogida_del_pool()
	if escogida != null:
		return _desde_escogida(escogida)
	return _pieza_normal()

## Pieza escogida que toca en este turno: primero la secuencia inicial, luego los turnos concretos.
func _escogida_para_turno(turno: int) -> PiezaEscogida:
	var config = Tetris.de(self).Configuracion
	if config == null:
		return null
	if turno >= 1 and turno <= config.SECUENCIA_INICIAL.size():
		var de_secuencia: PiezaEscogida = config.SECUENCIA_INICIAL[turno - 1]
		if de_secuencia != null:
			return de_secuencia
	for entrada in config.PIEZAS_EN_TURNO:
		if entrada != null and entrada.pieza != null and entrada.turno == turno:
			return entrada.pieza
	return null

## Sorteo con peso entre las piezas del pool y la pieza normal. null = sale una normal.
func _escogida_del_pool() -> PiezaEscogida:
	var config = Tetris.de(self).Configuracion
	if config == null or config.POOL_PIEZAS.is_empty():
		return null
	var total := maxf(config.PESO_PIEZA_NORMAL, 0.0)
	for entrada in config.POOL_PIEZAS:
		if entrada != null and entrada.pieza != null:
			total += maxf(entrada.peso, 0.0)
	if total <= 0.0:
		return null
	var umbral := randf() * total
	var acumulado := 0.0
	for entrada in config.POOL_PIEZAS:
		if entrada == null or entrada.pieza == null:
			continue
		acumulado += maxf(entrada.peso, 0.0)
		if umbral < acumulado:
			return entrada.pieza
	return null

## Construye la pieza a partir de una PiezaEscogida.
func _desde_escogida(escogida: PiezaEscogida) -> PiezaGenerada:
	if not FORMAS.has(escogida.forma):
		push_error("PiezaEscogida con forma desconocida '%s': se genera una pieza normal." % escogida.forma)
		return _pieza_normal()

	var pieza = PiezaGenerada.new()
	pieza.nombre = escogida.forma
	pieza.escogida = true
	pieza.forma = FORMAS[escogida.forma]
	pieza.textura_fondo = TEXTURAS_COLOR[escogida.forma]
	pieza.bioma = escogida.bioma
	pieza.textura_marco = Catalogo.marco_bioma(pieza.bioma)

	if escogida.sin_habitacion:
		pieza.sin_habitacion = true
		return pieza

	pieza.solo_horizontal = escogida.solo_horizontal

	var candidatas := _candidatas(pieza.bioma)
	var pesos := _pesos_de(candidatas)
	for i in pieza.forma.size():
		var categoria: CategoriaSala = null
		if i < escogida.categorias.size():
			categoria = escogida.categorias[i]
		if categoria == null:
			categoria = _elegir_categoria(candidatas, pesos)
		pieza.categorias.append(categoria)
	return pieza

## Pieza aleatoria normal, con las probabilidades y pesos del nivel.
func _pieza_normal() -> PiezaGenerada:
	var nombre = pieza_aleatoria()

	var pieza = PiezaGenerada.new()
	pieza.nombre = nombre
	pieza.forma = FORMAS[nombre]
	pieza.textura_fondo = TEXTURAS_COLOR[nombre]

	var biomas := _obtener_biomas()
	pieza.bioma = biomas.pick_random()
	pieza.textura_marco = Catalogo.marco_bioma(pieza.bioma)

	# Sin habitación: sigue siendo una pieza normal, pero sin categorías (ni icono ni letra).
	if _sale_sin_habitacion():
		pieza.sin_habitacion = true
		return pieza

	pieza.solo_horizontal = _sale_solo_horizontal()

	var candidatas := _candidatas(pieza.bioma)
	var pesos := _pesos_de(candidatas)
	for i in pieza.forma.size():
		pieza.categorias.append(_elegir_categoria(candidatas, pesos))

	return pieza

## Tira la probabilidad de que la pieza salga sin habitación (PROBABILIDAD_SIN_HABITACION).
func _sale_sin_habitacion() -> bool:
	var config = Tetris.de(self).Configuracion
	if config == null:
		return false
	return randf() * 100.0 < config.PROBABILIDAD_SIN_HABITACION

## Tira la probabilidad de que la pieza salga solo horizontal (PROBABILIDAD_SOLO_HORIZONTAL).
## Solo se tira para piezas con habitación (las otras salen antes de llegar aquí).
func _sale_solo_horizontal() -> bool:
	var config = Tetris.de(self).Configuracion
	if config == null:
		return false
	return randf() * 100.0 < config.PROBABILIDAD_SOLO_HORIZONTAL

## Biomas del nivel: los que tienen salas en el ContenidoSalas. Sin pools, Medieval.
func _obtener_biomas() -> Array[int]:
	var config = Tetris.de(self).Configuracion
	var biomas: Array[int] = []
	if config != null and config.CONTENIDO != null:
		biomas = config.CONTENIDO.biomas_disponibles()
	if biomas.is_empty():
		biomas = [Catalogo.Bioma.MEDIEVAL]
	return biomas

## Categorías que pueden salir en este bioma: solo las que tienen salas en su pool.
func _candidatas(bioma: int) -> Array[CategoriaSala]:
	var config = Tetris.de(self).Configuracion
	if config != null and config.CONTENIDO != null:
		var disponibles: Array[CategoriaSala] = config.CONTENIDO.categorias_disponibles(bioma)
		if not disponibles.is_empty():
			return disponibles
	if not _avisado_sin_categorias:
		_avisado_sin_categorias = true
		push_warning("Ninguna categoría tiene salas en su pool: los cuadrados saldrán sin categoría.")
	return []

func _pesos_de(candidatas: Array[CategoriaSala]) -> Array[float]:
	var config = Tetris.de(self).Configuracion
	var pesos: Array[float] = []
	var total := 0.0
	for categoria in candidatas:
		var peso: float = 1.0 if config == null else config.peso_de(categoria)
		pesos.append(peso)
		total += peso
	if total <= 0.0 and not pesos.is_empty():
		push_warning("Todos los pesos de categoría están en 0; usando uniforme.")
		for i in pesos.size():
			pesos[i] = 1.0
	return pesos

func _elegir_categoria(candidatas: Array[CategoriaSala], pesos: Array[float]) -> CategoriaSala:
	if candidatas.is_empty():
		return null
	var total := 0.0
	for peso in pesos:
		total += peso
	var umbral := randf() * total
	var acumulado := 0.0
	for i in candidatas.size():
		acumulado += pesos[i]
		if umbral <= acumulado:
			return candidatas[i]
	return candidatas[-1]
