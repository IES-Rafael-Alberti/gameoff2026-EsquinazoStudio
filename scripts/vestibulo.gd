class_name Vestibulo
extends Node2D
## Sala con una puerta por columna del tablero.
## INFERIOR: sus puertas miran al norte (hacia la fila de abajo del tablero).
## SUPERIOR: es la misma escena de tramo volteada en vertical (scale.y = -1),
## y sus puertas miran al sur (hacia la fila de arriba).

signal puerta_cruzada(columna: int)

enum Tipo { INFERIOR, SUPERIOR }

const ESCENA_TRAMO := preload("res://scenes/vestibulo_tramo.tscn")

@export var tipo := Tipo.INFERIOR
## Ancho de un tramo (puerta + pared). Debe coincidir con el de la escena del tramo.
@export var ancho_tramo := 128.0
## Dónde aparece el jugador respecto al centro de su puerta, hacia dentro del vestíbulo.
@export var desplazamiento_entrada := Vector2(0, 96)

var _puertas: Array[Puerta] = []


## Se llama una sola vez, con el número de columnas del tablero.
func construir(columnas: int) -> void:
	scale = Vector2(1, -1) if tipo == Tipo.SUPERIOR else Vector2.ONE
	var direccion := Puerta.Direccion.NORTE if tipo == Tipo.INFERIOR else Puerta.Direccion.SUR

	for columna in columnas:
		var tramo := ESCENA_TRAMO.instantiate() as Node2D
		tramo.position = Vector2(columna * ancho_tramo, 0)
		var puerta := tramo.get_node("Puerta") as Puerta
		puerta.direccion = direccion
		puerta.jugador_cruzo.connect(_on_jugador_cruzo.bind(columna))
		add_child(tramo)
		_puertas.append(puerta)


## true = hay sala al otro lado y la puerta se abre; false = queda cerrada.
func establecer_puerta(columna: int, abierta: bool) -> void:
	if columna >= 0 and columna < _puertas.size():
		_puertas[columna].establecer_conectada(abierta)


## Posición global donde colocar al jugador cuando entra por la puerta de esta columna.
func posicion_entrada(columna: int) -> Vector2:
	var puerta := _puertas[columna]
	var tramo := puerta.get_parent() as Node2D
	return to_global(tramo.position + puerta.position + desplazamiento_entrada)


func _on_jugador_cruzo(_puerta: Puerta, columna: int) -> void:
	puerta_cruzada.emit(columna)
