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
	"L": Color("#FF9100")
}

# Obtener una pieza aleatoria
func pieza_aleatoria() -> String:
	var nombres = FORMAS.keys()
	return nombres.pick_random()
