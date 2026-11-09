class_name PoolBioma
extends Resource
## Todas las salas posibles de un bioma, agrupadas por categoría.

@export var bioma: Catalogo.Bioma = Catalogo.Bioma.MEDIEVAL
@export var categorias: Array[PoolCategoria] = []


func pool_de(categoria: CategoriaSala) -> PoolCategoria:
	for pool in categorias:
		if pool != null and pool.categoria == categoria:
			return pool
	return null


## Categorías de este bioma que tienen al menos una sala.
func categorias_disponibles() -> Array[CategoriaSala]:
	var disponibles: Array[CategoriaSala] = []
	for pool in categorias:
		if pool != null and pool.categoria != null and pool.tiene_salas() and not disponibles.has(pool.categoria):
			disponibles.append(pool.categoria)
	return disponibles
