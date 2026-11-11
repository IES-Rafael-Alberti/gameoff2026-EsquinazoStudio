class_name Peligro
extends Area2D
## Base de las trampas que dañan al jugador al tocarlas. La forma del Area2D es la zona
## que hace daño. Una trampa nueva (sierra, llama...) usa este script o hereda de él.
## El daño empuja al jugador hacia fuera del peligro; la invulnerabilidad la gestiona el jugador.

## Daño por contacto.
@export var dano := 1
## Segundos mínimos entre dos daños de este mismo peligro.
@export var intervalo_dano := 0.5
## Se puede apagar (láseres, interruptores...) sin quitarlo de la sala.
@export var activo := true

var _enfriamiento := 0.0


func _ready() -> void:
	add_to_group("peligro")


func _physics_process(delta: float) -> void:
	_enfriamiento = maxf(_enfriamiento - delta, 0.0)
	if not activo or _enfriamiento > 0.0:
		return
	for cuerpo in get_overlapping_bodies():
		if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dano, global_position)
			_enfriamiento = intervalo_dano
			return
