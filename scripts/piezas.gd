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

# Colores de cada pieza
const COLORES = {
	"I": Color("#00E5FF"),
	"O": Color("#FFD600"),
	"T": Color("#AA00FF"),
	"S": Color("#00E676"),
	"Z": Color("#FF1744"),
	"J": Color("#2979FF"),
	"L": Color("#FF9100"),
	"X": Color("#FFD600"),
	"TT": Color("#FF9100"),
	"H": Color("#2979FF"),
	"P": Color("#AA00FF"),
	"+": Color("#00E676"),
	"C": Color("#FF1744"),
	"-": Color("#00E5FF")
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
