class_name EnemigoCohete
extends EnemigoEstados
## Enemigo cohete: persigue al jugador y explota al chocar con él o con una pared. La lógica de
## cuándo choca la lleva su estado PerseguirCohete; la de la explosión, el estado Explosion.
##
## Explotar es morir: cuenta como enemigo muerto (desafío resuelto, y suelta botín si lo tiene),
## pero con la animación y el daño en área de Explosion en vez del estado Muerte normal. Si lo
## mata el jugador, muere con el estado Muerte de siempre.
##
## Para que choque con las paredes, su máscara de colisión debe incluir Muros (aunque sea
## volador). La detección del jugador es la zona de contacto de Enemigo.

var _explotando := false


## Lo llama el estado PerseguirCohete al chocar.
func explotar() -> void:
	if _explotando or vida == null or not vida.esta_viva():
		return
	_explotando = true
	vida.recibir_dano(vida.vida) # murio: desafío y botín; luego morir() elige la explosión


func morir() -> void:
	if _explotando and maquina != null and maquina.tiene(EstadoExplosion.EXPLOSION):
		maquina.cambiar_a(EstadoExplosion.EXPLOSION)
	else:
		super.morir()


## true si el jugador está dentro de su zona de contacto.
func toca_al_jugador() -> bool:
	if _zona_contacto == null:
		return false
	for cuerpo in _zona_contacto.get_overlapping_bodies():
		if cuerpo.is_in_group("jugador"):
			return true
	return false
