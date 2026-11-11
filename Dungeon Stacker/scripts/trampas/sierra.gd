class_name Sierra
extends Peligro
## Sierra: cuando el jugador está en su línea (arriba, abajo, izquierda o derecha) y la ve,
## sale disparada en esa dirección hasta chocar con algo (muro, caja, otra sierra...) y
## vuelve a su sitio. Hasta que no está de vuelta en su sitio, no puede volver a atacar.
## Hace daño al contacto por ser un Peligro. Gira sobre sí misma mientras se mueve:
## solo gira el dibujo (hijo "Visual"), nunca el nodo raíz ni sus colisiones.

enum Estado { REPOSO, ATACANDO, VOLVIENDO }

## En el orden de Puerta.Direccion: Norte, Este, Sur, Oeste.
const VECTORES := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]

@export_group("Ataque")
## Direcciones en las que ataca. Por defecto, las cuatro.
@export_flags("Norte", "Este", "Sur", "Oeste") var direcciones := 15
@export var velocidad := 300.0
@export var velocidad_retorno := 120.0
## Segundos que el jugador debe llevar alineado (y a la vista) antes de que ataque. 0 = al instante.
@export var tiempo_alineado_minimo := 0.0
## Segundos que espera en su sitio tras volver, antes de poder atacar otra vez.
@export var pausa_entre_ataques := 0.3
## Grados por segundo que gira el dibujo mientras se mueve. 0 = no gira.
@export var velocidad_giro := 720.0

@export_group("Detección")
## Ancho de la franja en la que ve al jugador (píxeles). 64 = una casilla.
@export var ancho_deteccion := 64.0
## Distancia máxima a la que detecta al jugador. 0 = toda la sala.
@export var alcance_deteccion := 0.0

@export_group("Colisión")
## true: el jugador pasa por encima y solo recibe daño. false: la sierra es sólida.
@export var atravesable := true

var _estado := Estado.REPOSO
var _inicio := Vector2.ZERO
var _direccion := Vector2.ZERO
var _forma: Shape2D
var _cuerpo: CollisionObject2D # cuerpo sólido opcional (hijo "Cuerpo")
var _visual: Node2D # dibujo opcional que gira (hijo "Visual")
var _tiempo_alineado := 0.0
var _indice_alineado := -1
var _pausa := 0.0


func _ready() -> void:
	super._ready()
	_inicio = global_position
	_cuerpo = get_node_or_null("Cuerpo") as CollisionObject2D
	if _cuerpo != null:
		_cuerpo.collision_layer = 0 if atravesable else 1
	_visual = get_node_or_null("Visual") as Node2D
	for hijo in get_children():
		if hijo is CollisionShape2D:
			_forma = _reducir(hijo.shape)
			break


func _physics_process(delta: float) -> void:
	super._physics_process(delta) # daño por contacto
	match _estado:
		Estado.REPOSO:
			_vigilar(delta)
		Estado.ATACANDO:
			_atacar(delta)
		Estado.VOLVIENDO:
			_volver(delta)
	# Gira mientras se mueve (atacando o volviendo); quieta en reposo.
	if _visual != null and _estado != Estado.REPOSO:
		_visual.rotation += deg_to_rad(velocidad_giro) * delta


## En reposo: busca al jugador en alguno de sus ejes permitidos.
func _vigilar(delta: float) -> void:
	if _pausa > 0.0:
		_pausa -= delta
		return
	var jugador := _jugador()
	if not activo or jugador == null:
		_tiempo_alineado = 0.0
		_indice_alineado = -1
		return

	var objetivo := _posicion_de(jugador)
	var indice := _direccion_hacia(objetivo)
	if indice < 0 or not _linea_libre(objetivo):
		_tiempo_alineado = 0.0
		_indice_alineado = -1
		return

	if indice != _indice_alineado:
		_indice_alineado = indice
		_tiempo_alineado = 0.0
	else:
		_tiempo_alineado += delta
	if _tiempo_alineado >= tiempo_alineado_minimo:
		_direccion = VECTORES[indice]
		_estado = Estado.ATACANDO


func _atacar(delta: float) -> void:
	var paso: Vector2 = _direccion * velocidad * delta
	if _hay_obstaculo(global_position + paso):
		_estado = Estado.VOLVIENDO
		return
	global_position += paso


func _volver(delta: float) -> void:
	var hacia := _inicio - global_position
	var paso := velocidad_retorno * delta
	if hacia.length() <= paso:
		global_position = _inicio
		_estado = Estado.REPOSO
		_pausa = pausa_entre_ataques
		_tiempo_alineado = 0.0
		_indice_alineado = -1
	else:
		global_position += hacia.normalized() * paso


## Índice (0-3) de la dirección permitida en la que el jugador está en la franja, o -1.
func _direccion_hacia(objetivo: Vector2) -> int:
	var d := objetivo - global_position
	for i in VECTORES.size():
		if not (direcciones & (1 << i)):
			continue
		var v: Vector2 = VECTORES[i]
		var avance := d.dot(v)
		var lateral := absf(d.dot(Vector2(-v.y, v.x)))
		if avance > 0.0 and lateral <= ancho_deteccion * 0.5 \
				and (alcance_deteccion <= 0.0 or avance <= alcance_deteccion):
			return i
	return -1


## Un rayo hasta el jugador: si choca antes con otra cosa, hay un obstáculo en medio.
func _linea_libre(objetivo: Vector2) -> bool:
	var mascara := Capas.MUROS | Capas.JUGADOR | Capas.CAJAS | Capas.ENEMIGOS | Capas.SIERRAS
	var consulta := PhysicsRayQueryParameters2D.create(global_position, objetivo, mascara)
	consulta.exclude = _propios()
	var resultado := get_world_2d().direct_space_state.intersect_ray(consulta)
	if resultado.is_empty():
		return true
	return Capas.esta_en(resultado.collider, Capas.JUGADOR)


## ¿Hay algo que impida estar en esta posición? Muros, cajas, enemigos, otras sierras... y el
## jugador si la sierra no es atravesable.
func _hay_obstaculo(posicion: Vector2) -> bool:
	var mascara := Capas.MUROS | Capas.CAJAS | Capas.SIERRAS
	if not atravesable:
		mascara |= Capas.JUGADOR
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = _forma
	consulta.transform = Transform2D(0.0, posicion)
	consulta.collision_mask = mascara
	consulta.collide_with_areas = true # ve la zona de las otras sierras
	consulta.exclude = _propios()
	return not get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()


func _propios() -> Array[RID]:
	var rids: Array[RID] = [get_rid()]
	if _cuerpo != null:
		rids.append(_cuerpo.get_rid())
	return rids


## Forma de colisión del movimiento: la de daño, un poco más pequeña.
func _reducir(forma: Shape2D) -> Shape2D:
	var copia := forma.duplicate() as Shape2D
	if copia is CircleShape2D:
		copia.radius = maxf(copia.radius - 4.0, 1.0)
	elif copia is RectangleShape2D:
		copia.size = (copia.size - Vector2(8.0, 8.0)).max(Vector2.ONE)
	return copia


func _jugador() -> CharacterBody2D:
	for nodo in get_tree().get_nodes_in_group("jugador"):
		if nodo is CharacterBody2D:
			return nodo
	return null


## Centro del cuerpo del jugador (su origen está en los pies).
func _posicion_de(jugador: CharacterBody2D) -> Vector2:
	if jugador.has_method("centro"):
		return jugador.centro()
	return jugador.global_position
