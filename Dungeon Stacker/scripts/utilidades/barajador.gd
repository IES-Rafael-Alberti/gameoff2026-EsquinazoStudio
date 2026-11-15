class_name BarajadorPosiciones
extends Node2D
## Pon objetos (cofres, pociones, enemigos, puzles, trampas, lo que sea) como hijos de este
## nodo y, al cargar la sala, se reparten entre ellos sus posiciones al azar. Solo se cambia
## la posición de cada hijo: su estructura interna no se toca.
##
## El reparto se decide una sola vez por sala y es siempre el mismo al volver a ella: sale de
## la semilla de la celda (CeldaTablero.semilla) y de la ruta de este nodo en la sala. Fuera
## de una sala (escena suelta) se baraja distinto cada vez.
##
## Se baraja en _enter_tree, antes del _ready de los hijos, para que las cosas que se
## identifican por su posición (cofres, pociones, minas, llaves) ya la tengan definitiva.
##
## Cuidado: no pongas aquí cosas cuya posición dependa de otras que no se barajan (por
## ejemplo, una placa que debe quedar junto a su puerta), ni objetos de tamaños muy distintos
## que puedan solaparse con el muro al cambiar de hueco.

## Marcado: un objeto puede acabar en el hueco que ya tenía (barajado puro). Desmarcado:
## todos cambian de hueco. Con un solo hijo no hace nada.
@export var permitir_quedarse_en_su_sitio := true

## Intentos de barajado sin puntos fijos antes de recurrir a un desplazamiento fijo.
const MAX_INTENTOS := 50


func _enter_tree() -> void:
	_barajar()


func _barajar() -> void:
	var objetos: Array[Node2D] = []
	for hijo in get_children():
		if hijo is Node2D:
			objetos.append(hijo)
	if objetos.size() < 2:
		return

	var posiciones: Array[Vector2] = []
	for objeto in objetos:
		posiciones.append(objeto.position)

	var orden := _permutacion(objetos.size(), _crear_azar())
	for i in objetos.size():
		objetos[i].position = posiciones[orden[i]]


func _crear_azar() -> RandomNumberGenerator:
	var azar := RandomNumberGenerator.new()
	var habitacion := _buscar_habitacion()
	if habitacion == null or habitacion.datos == null:
		azar.randomize()
	else:
		azar.seed = hash([habitacion.datos.semilla, "barajador", str(habitacion.get_path_to(self))])
	return azar


## Devuelve una ordenación de 0..n-1 (Fisher-Yates). Si no se permite quedarse en su sitio,
## repite hasta que ningún índice coincida con su posición.
func _permutacion(n: int, azar: RandomNumberGenerator) -> Array[int]:
	var orden: Array[int] = []
	for intento in MAX_INTENTOS:
		orden = _barajada(n, azar)
		if permitir_quedarse_en_su_sitio or not _tiene_puntos_fijos(orden):
			return orden
	# Muy improbable: se garantiza un resultado válido desplazando todos un hueco.
	orden.clear()
	for i in n:
		orden.append((i + 1) % n)
	return orden


func _barajada(n: int, azar: RandomNumberGenerator) -> Array[int]:
	var orden: Array[int] = []
	for i in n:
		orden.append(i)
	for i in range(n - 1, 0, -1):
		var j := azar.randi_range(0, i)
		var tmp := orden[i]
		orden[i] = orden[j]
		orden[j] = tmp
	return orden


func _tiene_puntos_fijos(orden: Array[int]) -> bool:
	for i in orden.size():
		if orden[i] == i:
			return true
	return false


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
