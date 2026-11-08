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

# Obtener una pieza aleatoria
func pieza_aleatoria() -> String:
	var nombres = FORMAS.keys()
	return nombres.pick_random()

func generar_pieza() -> PiezaGenerada:
	var nombre = pieza_aleatoria()

	var pieza = PiezaGenerada.new()
	pieza.nombre = nombre
	pieza.forma = FORMAS[nombre]
	pieza.textura_fondo = TEXTURAS_COLOR[nombre]

	var biomas := _obtener_biomas()
	pieza.bioma = biomas.pick_random()
	pieza.textura_marco = Catalogo.marco_bioma(pieza.bioma)

	var pesos := _obtener_pesos()
	for i in pieza.forma.size():
		pieza.categorias.append(_elegir_categoria(pesos))

	return pieza
	
func _obtener_biomas() -> Array[int]:
	var config = Tetris.de(self).Configuracion
	var biomas: Array[int] = []
	if config != null:
		biomas = config.BIOMAS_NIVEL.duplicate()
	if biomas.is_empty():
		biomas = [Catalogo.Bioma.MEDIEVAL]
	return biomas

func _obtener_pesos() -> Array[float]:
	var pesos: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
	var config = Tetris.de(self).Configuracion
	if config != null:
		pesos[0] = maxf(config.PESO_CATEGORIA_A, 0.0)
		pesos[1] = maxf(config.PESO_CATEGORIA_B, 0.0)
		pesos[2] = maxf(config.PESO_CATEGORIA_C, 0.0)
		pesos[3] = maxf(config.PESO_CATEGORIA_D, 0.0)
		pesos[4] = maxf(config.PESO_CATEGORIA_E, 0.0)
		pesos[5] = maxf(config.PESO_CATEGORIA_F, 0.0)

	var total := 0.0
	for peso in pesos:
		total += peso
	if total <= 0.0:
		push_warning("Todos los pesos de categoría están en 0; usando uniforme.")
		for i in pesos.size():
			pesos[i] = 1.0

	return pesos

func _elegir_categoria(pesos: Array[float]) -> int:
	var total := 0.0
	for peso in pesos:
		total += peso

	var umbral := randf() * total
	var acumulado := 0.0
	for i in pesos.size():
		acumulado += pesos[i]
		if umbral <= acumulado:
			return i

	return pesos.size() - 1
