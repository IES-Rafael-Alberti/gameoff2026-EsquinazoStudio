class_name BloqueoNavegacion
extends Node2D
## Pon uno como hijo de una trampa fija (o de cualquier objeto que no se mueva). Al cargar
## la sala quita la malla de navegación de su casilla, o de todas las casillas cuyo centro
## esté a menos de "radio" píxeles, para que los enemigos que andan no pasen por ahí.
## El nodo debe estar en el centro del objeto.

## Lado de una casilla en píxeles.
const TAM_CELDA := 64.0

## 0 = solo la casilla en la que está. Mayor que 0 = todas las casillas cuyo centro esté
## a esa distancia o menos (la giratoria usa el alcance de sus palos).
@export var radio := 0.0


func _ready() -> void:
	# Diferido: el padre puede ajustar el radio en su propio _ready, que corre después.
	_bloquear.call_deferred()


func _bloquear() -> void:
	if not is_inside_tree():
		return
	var capa := _buscar_capa()
	if capa == null:
		push_warning("%s no encuentra la CapaSuelo de su sala: no bloqueará la navegación." % name)
		return
	var central := capa.local_to_map(capa.to_local(global_position))
	var rango := ceili(radio / TAM_CELDA) + 1
	var celdas: Array[Vector2i] = []
	for dy in range(-rango, rango + 1):
		for dx in range(-rango, rango + 1):
			var celda := central + Vector2i(dx, dy)
			if celda == central:
				celdas.append(celda)
			elif capa.to_global(capa.map_to_local(celda)).distance_to(global_position) <= radio:
				celdas.append(celda)
	capa.bloquear(celdas)


func _buscar_capa() -> CapaSuelo:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	if nodo == null:
		return null
	return nodo.get_node_or_null("TileMapLayer") as CapaSuelo
