class_name PoolCategoria
extends Resource
## Las salas posibles de una categoría dentro de un bioma.

@export var categoria: CategoriaSala
@export var salas: Array[EntradaSala] = []


## Una categoría solo cuenta si tiene al menos una sala válida.
func tiene_salas() -> bool:
	for entrada in salas:
		if _es_valida(entrada):
			return true
	return false


## Elige una sala al azar según los pesos. null si no hay ninguna.
func elegir() -> PackedScene:
	var validas: Array[EntradaSala] = []
	var total := 0.0
	for entrada in salas:
		if _es_valida(entrada):
			validas.append(entrada)
			total += entrada.peso
	if validas.is_empty():
		return null

	var umbral := randf() * total
	var acumulado := 0.0
	for entrada in validas:
		acumulado += entrada.peso
		if umbral <= acumulado:
			return entrada.escena
	return validas[-1].escena


func _es_valida(entrada: EntradaSala) -> bool:
	return entrada != null and entrada.escena != null and entrada.peso > 0.0
