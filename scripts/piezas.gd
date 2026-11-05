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

const MARCOS_NIVEL = {
	1: preload("res://assets/sprites/piezas/Marco medieval.png")
}

# Obtener una pieza aleatoria
func pieza_aleatoria() -> String:
	var nombres = FORMAS.keys()
	return nombres.pick_random()

func generar_pieza(tipo_nivel: int = 1) -> PiezaGenerada:
	var nombre = pieza_aleatoria()

	var pieza = PiezaGenerada.new()
	pieza.nombre = nombre
	pieza.forma = FORMAS[nombre]
	pieza.textura_fondo = TEXTURAS_COLOR[nombre]
	pieza.textura_marco = MARCOS_NIVEL.get(tipo_nivel, MARCOS_NIVEL[1])

	for i in pieza.forma.size():
		pieza.categorias.append(_elegir_categoria())
	return pieza
	
func _elegir_categoria() -> int:
	# De momento todas las celdas son A; aquí irán las probabilidades A-F.
	return Cuadrado.Categoria.A
