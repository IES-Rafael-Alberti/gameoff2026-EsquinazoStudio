class_name EntradaSala
extends Resource
## Una sala posible dentro de un pool.

@export var escena: PackedScene
## Probabilidad relativa dentro de su pool: 3 sale el triple de veces que 1.
@export_range(0.0, 100.0, 0.1) var peso := 1.0
