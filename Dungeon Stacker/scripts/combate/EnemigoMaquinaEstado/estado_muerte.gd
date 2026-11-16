class_name EstadoMuerte
extends Estado
## Muerte: el enemigo se para, deja de colisionar y de hacer daño, reproduce su animación y,
## cuando esta termina, se borra. Como el desafío de la sala se resuelve al salir del árbol, las
## puertas se abren cuando acaba la animación. De aquí no se vuelve.
##
## La animación "muerte" del AnimationPlayer no debe estar en bucle. Si no existe, el enemigo se
## borra pasados "duracion_sin_animacion" segundos.

## Solo si no hay animación de muerte: segundos hasta borrarse.
@export var duracion_sin_animacion := 0.0

var _restante := 0.0
var _esperando_animacion := false


func _init() -> void:
	animacion = &"muerte"


func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	enemigo.parar()
	for hijo in enemigo.get_children():
		if hijo is CollisionShape2D:
			hijo.set_deferred("disabled", true)
	if enemigo._zona_contacto != null:
		enemigo._zona_contacto.set_deferred("monitoring", false)

	var reproductor := enemigo.reproductor
	_esperando_animacion = reproductor != null and animacion != &"" \
			and reproductor.has_animation(animacion)
	if _esperando_animacion:
		reproductor.animation_finished.connect(_on_animacion_terminada)
	else:
		_restante = duracion_sin_animacion
		if _restante <= 0.0:
			enemigo.queue_free()


func fisica(delta: float) -> void:
	if _esperando_animacion:
		return
	_restante -= delta
	if _restante <= 0.0:
		enemigo.queue_free()


func es_invulnerable() -> bool:
	return true


func hace_dano_contacto() -> bool:
	return false


func _on_animacion_terminada(nombre: StringName) -> void:
	if nombre == animacion:
		enemigo.queue_free()
