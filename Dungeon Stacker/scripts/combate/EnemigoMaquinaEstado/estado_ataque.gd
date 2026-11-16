class_name EstadoAtaque
extends Estado
## Ataque del enemigo, en tres fases: anticipación (quieto, avisando), golpe y recuperación
## (quieto). Después vuelve a Perseguir. Dos tipos:
##   Cuerpo a cuerpo: durante el golpe la ZonaGolpe (un Area2D del enemigo que tú colocas, con
##     su forma apuntando a la derecha) se orienta hacia el jugador y le hace daño una vez.
##   Embestida: durante el golpe se lanza en línea recta, en la dirección en que estaba el
##     jugador al empezar, y hace su daño por contacto normal. Acaba antes si choca con algo.
## Perseguir pasa a este estado cuando el jugador está a menos de "rango" y ha pasado el
## enfriamiento. Con rango 0 nunca ataca.
##
## Animaciones opcionales (del AnimationPlayer del enemigo), una por fase.

enum Tipo { CUERPO_A_CUERPO, EMBESTIDA }
enum Fase { ANTICIPACION, GOLPE, RECUPERACION }

@export var tipo := Tipo.CUERPO_A_CUERPO

@export_group("Cuándo ataca")
## Distancia (píxeles) al jugador a la que empieza a atacar. 0 = no ataca nunca.
@export var rango := 48.0
## Segundos desde que acaba un ataque hasta que puede empezar otro.
@export var enfriamiento := 1.5

@export_group("Tiempos")
## Segundos quieto avisando antes del golpe.
@export var anticipacion := 0.4
## Segundos que dura el golpe (en la embestida, lo que dura el empujón).
@export var duracion_golpe := 0.2
## Segundos quieto después del golpe.
@export var recuperacion := 0.5

@export_group("Cuerpo a cuerpo")
## Zona de daño del golpe: un Area2D hijo del enemigo, con máscara Jugador.
@export var zona_golpe: Area2D
@export var dano := 1
## Si el jugador retrocede al recibir el golpe.
@export var empuja_al_jugador := false

@export_group("Embestida")
@export var velocidad_embestida := 240.0

@export_group("Animaciones")
@export var animacion_anticipacion: StringName = &"ataque_anticipacion"
@export var animacion_golpe: StringName = &"ataque_golpe"
@export var animacion_recuperacion: StringName = &"ataque_recuperacion"

var _fase := Fase.ANTICIPACION
var _restante := 0.0
var _direccion := Vector2.RIGHT
var _golpeo := false
var _listo_en_ms := 0 # instante (Time.get_ticks_msec) desde el que puede volver a atacar


func _ready() -> void:
	if zona_golpe != null:
		zona_golpe.monitoring = false


## Lo consulta Perseguir: distancia actual al jugador.
func puede_atacar(distancia: float) -> bool:
	return rango > 0.0 and distancia <= rango and Time.get_ticks_msec() >= _listo_en_ms


func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	enemigo.parar()
	var destino := enemigo.posicion_jugador()
	if destino != Vector2.INF and not destino.is_equal_approx(enemigo.global_position):
		_direccion = (destino - enemigo.global_position).normalized()
	if tipo == Tipo.CUERPO_A_CUERPO and zona_golpe != null:
		zona_golpe.rotation = _direccion.angle()
	_golpeo = false
	_empezar_fase(Fase.ANTICIPACION)


func fisica(delta: float) -> void:
	_restante -= delta
	match _fase:
		Fase.GOLPE:
			_actuar_golpe()
	if _restante > 0.0:
		return
	match _fase:
		Fase.ANTICIPACION:
			_empezar_fase(Fase.GOLPE)
		Fase.GOLPE:
			_empezar_fase(Fase.RECUPERACION)
		Fase.RECUPERACION:
			_terminar(PERSEGUIR)


func salir() -> void:
	if zona_golpe != null:
		zona_golpe.monitoring = false
	enemigo.parar()
	_listo_en_ms = Time.get_ticks_msec() + int(enfriamiento * 1000.0)


## En la embestida, solo hace daño por contacto durante el golpe; en el cuerpo a cuerpo, el
## daño lo hace la zona del golpe.
func hace_dano_contacto() -> bool:
	return tipo == Tipo.EMBESTIDA and _fase == Fase.GOLPE


func _empezar_fase(nueva: Fase) -> void:
	_fase = nueva
	match nueva:
		Fase.ANTICIPACION:
			_restante = anticipacion
			enemigo.reproducir(animacion_anticipacion)
		Fase.GOLPE:
			_restante = duracion_golpe
			enemigo.reproducir(animacion_golpe)
			if tipo == Tipo.CUERPO_A_CUERPO and zona_golpe != null:
				zona_golpe.monitoring = true
		Fase.RECUPERACION:
			_restante = recuperacion
			enemigo.reproducir(animacion_recuperacion)
			enemigo.parar()
			if zona_golpe != null:
				zona_golpe.monitoring = false


func _actuar_golpe() -> void:
	if tipo == Tipo.EMBESTIDA:
		enemigo.mover(_direccion * velocidad_embestida)
		if enemigo.get_slide_collision_count() > 0:
			_restante = 0.0 # choca con algo: acaba la embestida
		return
	if _golpeo or zona_golpe == null:
		return
	for cuerpo in zona_golpe.get_overlapping_bodies():
		if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_dano"):
			var origen := enemigo.global_position if empuja_al_jugador else Vector2.INF
			cuerpo.recibir_dano(dano, origen)
			_golpeo = true
			return
