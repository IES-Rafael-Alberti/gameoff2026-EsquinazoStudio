class_name EstadoExplosion
extends EstadoMuerte
## Muerte por explosión (la usa el EnemigoCohete al chocar). Al entrar hace daño a todo lo que
## esté dentro del radio: al jugador y a los demás enemigos. Después se comporta como Muerte: se
## para, deja de colisionar, reproduce su animación (por defecto "explosion") y, al acabar, se
## borra. El nodo de este estado debe llamarse "Explosion".
##
## El daño no empuja al jugador. Los enemigos que mueran por la explosión mueren con su Muerte
## normal (no explotan en cadena).
 
const EXPLOSION := &"Explosion"

## Radio (píxeles) de la explosión.
@export var radio := 64.0
## Daño al jugador y a los enemigos dentro del radio.
@export var dano := 1

func _init() -> void:
	animacion = &"explosion"

func entrar(anterior: StringName, datos: Dictionary) -> void:
	_danar_en_area()
	super.entrar(anterior, datos)

func _danar_en_area() -> void:
	var forma := CircleShape2D.new()
	forma.radius = radio
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, enemigo.global_position)
	consulta.collision_mask = Capas.JUGADOR | Capas.ENEMIGOS
	consulta.collide_with_areas = false
	consulta.exclude = [enemigo.get_rid()]
	var impactos := enemigo.get_world_2d().direct_space_state.intersect_shape(consulta, 32)
	for impacto in impactos:
		var cuerpo: Object = impacto.collider
		if cuerpo != null and cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dano)
