class_name Lanzaflechas
extends StaticBody2D
## Lanzaflechas de centro: un bloque sólido que dispara flechas siempre hacia donde apunta.
## Con rotation = 0 dispara hacia la derecha; al rotar el nodo, rota la dirección de disparo.
##
## Dos modos, elegibles por lanzador en el inspector:
##   Continuo: una flecha cada "cooldown" segundos.
##   Tandas:   "flechas_por_tanda" flechas seguidas, separadas "intervalo_tanda" segundos,
##             y luego "pausa_entre_tandas" segundos de descanso.
## Las flechas son hijas de la sala, así que desaparecen con ella al salir.
##
## En el editor: capa Muros (1), sin máscara.

enum Modo { CONTINUO, TANDAS }

## Se puede apagar (interruptores, puzles...) sin quitarlo de la sala.
@export var activo := true
@export var modo := Modo.CONTINUO

@export_group("Flecha")
## Escena de la flecha que dispara. Su raíz debe ser una Flecha.
@export var escena_flecha: PackedScene = preload("res://scenes/trampas/flecha.tscn")
## Distancia desde el centro del lanzador hasta donde nace la flecha, en píxeles.
@export var distancia_salida := 40.0

@export_group("Tiempos")
## Segundos que espera desde que carga la sala hasta el primer disparo.
@export var retraso_inicial := 0.0
## Modo Continuo: segundos entre dos flechas.
@export var cooldown := 1.5
## Modo Tandas: cuántas flechas salen seguidas.
@export var flechas_por_tanda := 3
## Modo Tandas: segundos entre dos flechas de la misma tanda.
@export var intervalo_tanda := 0.2
## Modo Tandas: segundos de descanso desde la última flecha de una tanda hasta la primera
## de la siguiente.
@export var pausa_entre_tandas := 2.0

# Segundos que faltan para el siguiente disparo.
var _espera := 0.0
# Flechas ya disparadas en la tanda actual.
var _disparadas_en_tanda := 0


func _ready() -> void:
	_espera = retraso_inicial


# Sin awaits: la sala se destruye al salir de ella y un temporizador pendiente
# intentaría seguir sobre un nodo que ya no existe.
func _physics_process(delta: float) -> void:
	if not activo:
		return
	_espera -= delta
	if _espera > 0.0:
		return
	_disparar()
	match modo:
		Modo.CONTINUO:
			_espera += maxf(cooldown, 0.05)
		Modo.TANDAS:
			_disparadas_en_tanda += 1
			if _disparadas_en_tanda >= flechas_por_tanda:
				_disparadas_en_tanda = 0
				_espera += maxf(pausa_entre_tandas, 0.05)
			else:
				_espera += maxf(intervalo_tanda, 0.05)


func _disparar() -> void:
	var flecha := escena_flecha.instantiate() as Flecha
	if flecha == null:
		push_error("La escena de flecha del lanzaflechas %s debe tener una Flecha como raíz." % name)
		return
	var direccion := Vector2.RIGHT.rotated(rotation)
	flecha.direccion = direccion
	flecha.emisor = self
	# Mismo padre que el lanzador, así sus coordenadas locales coinciden.
	flecha.position = position + direccion * distancia_salida
	get_parent().add_child.call_deferred(flecha)
