class_name SpawnerEnemigos
extends Node2D
## Invoca enemigos cada cierto tiempo en la posición de sus hijos Marker2D. No es físico: es un
## Node2D sin colisión ni dibujo (los marcadores solo se ven en el editor).
##
## Empieza a contar cuando el jugador entra en la sala y se apaga solo cuando se acaba el
## desafío de la sala (la señal desafios_resueltos de Habitacion). En una sala ya resuelta
## no hace nada y se borra.
##
## Por defecto los enemigos invocados NO cuentan como desafío: no bloquean las puertas ni
## impiden resolver la sala. La sala debe tener entonces otro desafío que sí se pueda resolver
## (un puzle, otros enemigos...) o el spawner no se apagaría nunca. Con cuenta_como_desafio
## (solo si tiene límite de apariciones), el spawner y todo lo que invoca son parte del desafío:
## la sala se resuelve cuando ya ha invocado todo y todos han muerto. Al aparecer se quedan
## quietos un instante (bloqueo_invocado de Enemigo). Son hijos de la sala, así que desaparecen
## con ella al salir.
##
## Estructura: este nodo con uno o varios Marker2D como hijos.

enum Reparto { EN_CADA_MARCADOR, UNO_AL_AZAR }

## Enemigo que invoca. La raíz de su escena debe ser un Enemigo.
@export var escena_enemigo: PackedScene
## En cada marcador: cada vez que toca invocar sale una copia en cada Marker2D.
## Uno al azar: sale una sola copia, en un marcador elegido al azar.
@export var reparto := Reparto.EN_CADA_MARCADOR

@export_group("Tiempos")
## Segundos desde que el jugador entra en la sala hasta la primera invocación.
@export var retraso_inicial := 0.0
## Segundos entre una invocación y la siguiente.
@export var intervalo := 5.0

@export_group("Límites")
## Cuántos enemigos invoca en total. 0 = sin límite.
@export_range(0, 999) var max_apariciones := 0
## No invoca mientras haya este número de enemigos suyos vivos; sigue cuando muere alguno.
## 0 = sin límite.
@export_range(0, 99) var max_vivos := 0

@export_group("Desafío de la sala")
## Si el spawner y los enemigos que invoca forman parte del desafío de la sala: las puertas
## siguen cerradas hasta que ha invocado todos (max_apariciones) y han muerto todos. Solo
## funciona con límite de apariciones (max_apariciones > 0): sin límite la sala no acabaría
## nunca, así que se ignora (y avisa en la consola).
@export var cuenta_como_desafio := false

@export_group("Al acabar el desafío")
## Si los enemigos invocados que sigan vivos desaparecen cuando el spawner se apaga.
@export var eliminar_invocados := true

var _habitacion: Habitacion
var _espera := 0.0
var _apariciones := 0
var _vivos: Array[Enemigo] = []
var _apagado := false
## cuenta_como_desafio ya filtrado: solo se cumple si tiene límite de apariciones.
var _es_desafio := false


func _ready() -> void:
	set_physics_process(false)
	_habitacion = _buscar_habitacion()
	if _habitacion == null:
		# Escena suelta (pruebas): empieza ya y no se apaga.
		_empezar()
		return
	if _habitacion.datos != null and _habitacion.datos.resuelta:
		queue_free()
		return
	if cuenta_como_desafio and max_apariciones == 0:
		push_warning("El spawner %s no tiene límite de apariciones: no puede ser parte del desafío (sería interminable)." % name)
	_es_desafio = cuenta_como_desafio and max_apariciones > 0
	if _es_desafio:
		_habitacion.registrar_desafio(self)
	_habitacion.jugador_entro.connect(_empezar, CONNECT_ONE_SHOT)
	_habitacion.desafios_resueltos.connect(_apagar)


# Sin awaits: la sala se destruye al salir de ella y un temporizador pendiente intentaría
# seguir sobre un nodo que ya no existe.
func _physics_process(delta: float) -> void:
	_espera -= delta
	if _espera > 0.0:
		return
	_espera += maxf(intervalo, 0.05)
	_invocar()


func _empezar() -> void:
	if _apagado:
		return
	_espera = retraso_inicial
	set_physics_process(true)


## El desafío de la sala se ha acabado: deja de invocar y, si toca, quita lo invocado.
func _apagar() -> void:
	print("[Spawner] apagado, vivos: ", _vivos.size())
	_apagado = true
	set_physics_process(false)
	if not eliminar_invocados:
		return
	for enemigo in _vivos.duplicate():
		if is_instance_valid(enemigo):
			enemigo.queue_free()
	_vivos.clear()


func _invocar() -> void:
	if escena_enemigo == null:
		push_warning("El spawner %s no tiene escena_enemigo." % name)
		set_physics_process(false)
		return
	var marcadores := _marcadores()
	if marcadores.is_empty():
		push_warning("El spawner %s no tiene ningún Marker2D hijo." % name)
		set_physics_process(false)
		return

	var elegidos: Array[Marker2D] = []
	if reparto == Reparto.UNO_AL_AZAR:
		elegidos.append(marcadores.pick_random())
	else:
		elegidos = marcadores

	for marcador in elegidos:
		if not _puede_invocar():
			break
		_crear(marcador)

	# Ya ha invocado todo lo que podía: deja de contar, pero sigue escuchando el fin del
	# desafío por si tiene que quitar lo invocado.
	if max_apariciones > 0 and _apariciones >= max_apariciones:
		set_physics_process(false)
		# Ya no queda nada por invocar: el spawner deja de ser desafío (los enemigos que
		# haya vivos siguen siéndolo hasta que mueran).
		if _es_desafio:
			_habitacion.resolver_desafio(self)


func _puede_invocar() -> bool:
	if max_apariciones > 0 and _apariciones >= max_apariciones:
		return false
	if max_vivos > 0 and _vivos.size() >= max_vivos:
		return false
	return true


func _crear(marcador: Marker2D) -> void:
	var nodo := escena_enemigo.instantiate()
	var enemigo := nodo as Enemigo
	if enemigo == null:
		push_error("La escena del spawner %s debe tener un Enemigo como raíz." % name)
		nodo.queue_free()
		set_physics_process(false)
		return
	var padre := get_parent() as Node2D
	if padre == null:
		push_error("El spawner %s debe ser hijo de un Node2D." % name)
		nodo.queue_free()
		set_physics_process(false)
		return

	enemigo.invocado = true
	enemigo.cuenta_como_desafio = _es_desafio
	enemigo.position = padre.to_local(marcador.global_position)
	padre.add_child(enemigo)

	_apariciones += 1
	_vivos.append(enemigo)
	enemigo.tree_exited.connect(_on_enemigo_salio.bind(enemigo), CONNECT_ONE_SHOT)


func _on_enemigo_salio(enemigo: Enemigo) -> void:
	_vivos.erase(enemigo)


func _marcadores() -> Array[Marker2D]:
	var lista: Array[Marker2D] = []
	for hijo in get_children():
		if hijo is Marker2D:
			lista.append(hijo)
	return lista


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
