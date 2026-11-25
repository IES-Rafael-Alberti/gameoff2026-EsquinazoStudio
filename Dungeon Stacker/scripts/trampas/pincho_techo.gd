class_name PinchosTecho
extends Area2D
## Trampa de pinchos que caen del techo. Armada, solo se ve un círculo en el suelo. Cuando el
## jugador (o un enemigo que anda) pisa la casilla, tras "retardo" el círculo desaparece y
## caen los pinchos. Los pinchos son una escena de pinchos estáticos que ya existe (hijo de
## esta, asignado en "pinchos"): ella hace el daño, en el golpe de la caída y mientras se
## permanezca (su propio intervalo_dano). Esta trampa solo la muestra, la mueve y la activa.
##
## Estructura: la raíz es esta Area2D con un CollisionShape2D que es la zona que activa la
## trampa (capa de trampas, máscara Jugador + Enemigos). Hijos: el círculo y la instancia de
## pinchos estáticos, colocada en su posición final (ya caída).

enum Modo {
	PERMANENTE, ## Los pinchos se quedan clavados (pincho estático).
	REARMAR, ## Tras duracion_activo suben (la caída al revés) y desaparecen; vuelve el círculo.
	UN_USO, ## Solo caen, hacen su golpe y desaparecen sin dejar nada. No se vuelve a activar.
}

enum Estado { ARMADO, CAYENDO, CAIDO, SUBIENDO, ENFRIANDO, AGOTADO }

@export var modo := Modo.REARMAR
@export_group("Tiempos")
## Segundos entre pisar el círculo y que caigan los pinchos. 0 = al instante.
@export_range(0.0, 5.0, 0.05, "suffix:s") var retardo := 0.4
## Segundos que están los pinchos abajo antes de subir (solo REARMAR).
@export_range(0.1, 30.0, 0.1, "suffix:s") var duracion_activo := 2.0
## Segundos desde que desaparecen hasta que vuelve el círculo (solo REARMAR).
@export_range(0.0, 30.0, 0.1, "suffix:s") var pausa_rearme := 1.0
@export_group("Caída")
## Altura (píxeles) desde la que caen (y a la que suben) los pinchos.
@export var altura_caida := 48.0
@export_range(0.01, 1.0, 0.01, "suffix:s") var duracion_caida := 0.1
@export_group("Dibujo")
## Círculo del suelo: se ve armado y se oculta al caer.
@export var circulo: CanvasItem
## Instancia de pinchos estáticos (cualquier Peligro). Oculta y sin daño hasta que cae.
@export var pinchos: Peligro

var _estado := Estado.ARMADO
var _posicion_pinchos := Vector2.ZERO
var _tween: Tween

func _ready() -> void:
	if pinchos == null:
		push_warning("%s no tiene asignados los pinchos." % name)
	else:
		_posicion_pinchos = pinchos.position
	_armar()

func _physics_process(_delta: float) -> void:
	if _estado != Estado.ARMADO:
		return
	for cuerpo in get_overlapping_bodies():
		if _activa_la_trampa(cuerpo):
			_disparar()
			return

func _activa_la_trampa(cuerpo: Node2D) -> bool:
	if cuerpo.is_in_group("jugador"):
		return true
	var enemigo := cuerpo as Enemigo
	return enemigo != null and not enemigo.volador

func _armar() -> void:
	_estado = Estado.ARMADO
	if circulo != null:
		circulo.visible = true
	_ocultar_pinchos()

func _disparar() -> void:
	_estado = Estado.CAYENDO
	_nuevo_tween()
	_tween.tween_interval(retardo)
	_tween.tween_callback(_empezar_caida)
	if pinchos != null:
		_tween.tween_property(pinchos, "position", _posicion_pinchos, duracion_caida)
	_tween.tween_callback(_impactar)

func _empezar_caida() -> void:
	if circulo != null:
		circulo.visible = false
	if pinchos != null:
		pinchos.position = _posicion_pinchos - Vector2(0.0, altura_caida)
		pinchos.visible = true

## Los pinchos ya están abajo: se activan (golpe a quien esté dentro y daño mientras se quede).
func _impactar() -> void:
	_estado = Estado.CAIDO
	if pinchos != null:
		pinchos.activo = true
	match modo:
		Modo.PERMANENTE:
			pass
		Modo.UN_USO:
			_retirar_tras_el_golpe()
		Modo.REARMAR:
			_nuevo_tween()
			_tween.tween_interval(duracion_activo)
			_tween.tween_callback(_subir)

## Un solo uso: espera a que el Peligro haya dado su golpe y desaparece sin dejar nada.
func _retirar_tras_el_golpe() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	_ocultar_pinchos()
	_estado = Estado.AGOTADO

## Rearmar: la caída al revés. Dejan de hacer daño nada más empezar a subir.
func _subir() -> void:
	_estado = Estado.SUBIENDO
	if pinchos == null:
		_terminar_de_subir()
		return
	pinchos.activo = false
	_nuevo_tween()
	_tween.tween_property(pinchos, "position", _posicion_pinchos - Vector2(0.0, altura_caida), duracion_caida)
	_tween.tween_callback(_terminar_de_subir)

func _terminar_de_subir() -> void:
	_ocultar_pinchos()
	_estado = Estado.ENFRIANDO
	_nuevo_tween()
	_tween.tween_interval(pausa_rearme)
	_tween.tween_callback(_armar)

func _ocultar_pinchos() -> void:
	if pinchos == null:
		return
	pinchos.activo = false
	pinchos.visible = false
	pinchos.position = _posicion_pinchos

func _nuevo_tween() -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
