class_name ContenidoSalas
extends Resource
## Los pools de salas de un nivel: un PoolBioma por bioma.

@export var biomas: Array[PoolBioma] = []


## Elige al azar, según los pesos, una sala de ese bioma y categoría. null si no hay ninguna.
func elegir(bioma: int, categoria: CategoriaSala) -> PackedScene:
	var pool_bioma := _pool_bioma(bioma)
	if pool_bioma == null or categoria == null:
		return null
	var pool := pool_bioma.pool_de(categoria)
	return null if pool == null else pool.elegir()


## Biomas que se pueden generar: los que tienen al menos una categoría con salas.
func biomas_disponibles() -> Array[int]:
	var disponibles: Array[int] = []
	for pool in biomas:
		if pool != null and not disponibles.has(pool.bioma) and not pool.categorias_disponibles().is_empty():
			disponibles.append(pool.bioma)
	return disponibles


## Categorías que se pueden generar en este bioma (las que tienen salas en su pool).
func categorias_disponibles(bioma: int) -> Array[CategoriaSala]:
	var pool_bioma := _pool_bioma(bioma)
	if pool_bioma == null:
		return []
	return pool_bioma.categorias_disponibles()


func _pool_bioma(bioma: int) -> PoolBioma:
	for pool in biomas:
		if pool != null and pool.bioma == bioma:
			return pool
	return null
