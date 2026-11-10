class_name PesoCategoria
extends Resource
## Probabilidad relativa de una categoría al generar los cuadrados de las piezas.

@export var categoria: CategoriaSala
@export_range(0.0, 100.0, 0.1) var peso := 1.0
