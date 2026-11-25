class_name JugadorResbalar
extends JugadorEstado
## Deslizamiento sobre hielo (baldosas con el custom data "hielo"). Al pisar hielo en movimiento
## el jugador sigue avanzando en esa dirección, sin poder cambiarla, hasta que choca con algo
## (pared, roca, caja, enemigo...) o llega a suelo normal. Sí puede atacar mientras resbala.
## Recibir daño no lo corta: el retroceso se aplica aquí.
##
## Dos modos (por_celdas):
##  - true: se encaja al centro de las baldosas, solo en 4 direcciones, y avanza de celda en
##    celda. Para sobre la primera celda de suelo normal, o en la última de hielo si la
##    siguiente está bloqueada.
##  - false: movimiento libre en la dirección con la que entró; para al tocar cualquier cosa
##    o en cuanto el centro del cuerpo está sobre suelo normal.

## Desliza de celda en celda (true) o en libre (false).
@export var por_celdas := true
@export_range(10.0, 600.0, 1.0, "suffix:px/s") var velocidad_deslizamiento := 180.0

var _direccion := Vector2.ZERO
## Centro global del cuerpo de la celda a la que va (solo por_celdas).
var _objetivo := Vector2.ZERO
var _atacando := false
var _tiempo_ataque := 0.0
var _golpe_dado := false


func entrar(_anterior: StringName, datos: Dictionary) -> void:
	_atacando = false
	_direccion = datos.get("direccion", Vector2.ZERO)
	var sala := jugador.habitacion()
	if _direccion == Vector2.ZERO or sala == null:
		_parar()
		return
	if por_celdas:
		_direccion = _a_cuatro_direcciones(_direccion)
		_objetivo = _primer_objetivo(sala)
	else:
		_direccion = _direccion.normalized()
	jugador.actualizar_direccion(_direccion)
	jugador.mostrar_pose_quieto()
	jugador.sprite.animation_finished.connect(_on_animacion_terminada)


func salir() -> void:
	if jugador.sprite.animation_finished.is_connected(_on_animacion_terminada):
		jugador.sprite.animation_finished.disconnect(_on_animacion_terminada)
	jugador.velocity = Vector2.ZERO


func fisica(delta: float) -> void:
	var sala := jugador.habitacion()
	if sala == null:
		_parar()
		return
	if _atacando:
		_tiempo_ataque += delta
		if not _golpe_dado and _tiempo_ataque >= jugador.retardo_golpe:
			_golpe_dado = true
			jugador.golpear()
	if jugador.avanzar_retroceso(delta):
		return
	if por_celdas:
		_fisica_celdas(sala, delta)
	else:
		_fisica_libre(sala)


func entrada(evento: InputEvent) -> void:
	if evento.is_action_pressed("accion") and not evento.is_echo() and not _atacando:
		_atacando = true
		_tiempo_ataque = 0.0
		_golpe_dado = false
		jugador.animar("Attack")


func _fisica_libre(sala: Habitacion) -> void:
	if not sala.es_hielo(jugador.centro()):
		_parar()
		return
	jugador.velocity = _direccion * velocidad_deslizamiento
	jugador.move_and_slide()
	if jugador.get_slide_collision_count() > 0:
		_parar()


func _fisica_celdas(sala: Habitacion, delta: float) -> void:
	var hacia := _objetivo - jugador.centro()
	if hacia.length() > velocidad_deslizamiento * delta:
		jugador.velocity = hacia.normalized() * velocidad_deslizamiento
		jugador.move_and_slide()
		# Algo se ha cruzado en medio y no se avanza: se acabó.
		if jugador.get_slide_collision_count() > 0 \
				and jugador.get_real_velocity().length() < velocidad_deslizamiento * 0.1:
			_parar()
		return

	# Llega al centro de la celda este mismo paso.
	jugador.velocity = hacia / delta
	jugador.move_and_slide()
	if not sala.es_hielo(_objetivo):
		_parar() # primera celda de suelo normal
		return
	var siguiente := sala.centro_de_celda(sala.celda_de(_objetivo) + Vector2i(_direccion))
	if jugador.test_move(jugador.global_transform, siguiente - _objetivo):
		_parar() # pared, roca, caja... en la siguiente celda
		return
	_objetivo = siguiente


## Primer destino: el centro de la celda que se pisa si aún está por delante; si ya se ha
## pasado, el de la siguiente.
func _primer_objetivo(sala: Habitacion) -> Vector2:
	var celda := sala.celda_de(jugador.centro())
	var centro := sala.centro_de_celda(celda)
	if (centro - jugador.centro()).dot(_direccion) < -0.01:
		centro = sala.centro_de_celda(celda + Vector2i(_direccion))
	return centro


func _a_cuatro_direcciones(direccion: Vector2) -> Vector2:
	if absf(direccion.x) >= absf(direccion.y):
		return Vector2(signf(direccion.x), 0.0)
	return Vector2(0.0, signf(direccion.y))


func _parar() -> void:
	jugador.velocity = Vector2.ZERO
	_terminar(INACTIVO)


func _on_animacion_terminada() -> void:
	if _atacando:
		_atacando = false
		jugador.mostrar_pose_quieto()
