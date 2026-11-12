class_name Peligro
extends Area2D
## Base de las trampas que dañan al tocarlas. La forma del Area2D es la zona que hace daño.
## Una trampa nueva (sierra, llama...) usa este script o hereda de él.
## Daña al jugador (que además retrocede, si retroceso está activo) y a los enemigos que
## andan; los voladores no les afecta.
## En el editor: capa Trampas (6), y máscara Jugador + Enemigos.

## Daño por contacto.
@export var dano := 1
## Segundos mínimos entre dos daños de esta trampa al mismo objetivo.
@export var intervalo_dano := 0.5
## Se puede apagar (láseres, interruptores...) sin quitarlo de la sala.
@export var activo := true
## Si también daña a los enemigos que andan.
@export var danar_enemigos := true
## Si el jugador retrocede al ser dañado. Desmarcado: recibe el daño sin que lo empujen.
@export var retroceso := true

# Cuerpo -> segundos que faltan para poder dañarlo otra vez.
var _enfriamientos := {}


func _ready() -> void:
	add_to_group("peligro")


func _physics_process(delta: float) -> void:
	_actualizar_enfriamientos(delta)
	if not activo:
		return
	for cuerpo in get_overlapping_bodies():
		if _enfriamientos.has(cuerpo):
			continue
		if _danar(cuerpo):
			_enfriamientos[cuerpo] = intervalo_dano


## Devuelve true si ha dañado al cuerpo.
func _danar(cuerpo: Node2D) -> bool:
	if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_dano"):
		var origen := global_position if retroceso else Vector2.INF
		cuerpo.recibir_dano(dano, origen)
		return true
	var enemigo := cuerpo as Enemigo
	if danar_enemigos and enemigo != null and not enemigo.volador:
		enemigo.recibir_dano(dano)
		return true
	return false


func _actualizar_enfriamientos(delta: float) -> void:
	for cuerpo in _enfriamientos.keys():
		if not is_instance_valid(cuerpo):
			_enfriamientos.erase(cuerpo)
			continue
		_enfriamientos[cuerpo] -= delta
		if _enfriamientos[cuerpo] <= 0.0:
			_enfriamientos.erase(cuerpo)
