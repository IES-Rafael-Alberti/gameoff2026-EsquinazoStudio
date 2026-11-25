class_name EstadoPerseguirCohete
extends EstadoPerseguir
## Perseguir del cohete: igual que EstadoPerseguir, pero si choca con una pared o toca al jugador
## explota. No hace daño por contacto: el daño lo hace la explosión.
## Solo vale en un EnemigoCohete.


func fisica(delta: float) -> void:
	super.fisica(delta)
	var cohete := enemigo as EnemigoCohete
	if cohete == null:
		return
	if cohete.get_slide_collision_count() > 0 or cohete.toca_al_jugador():
		cohete.explotar()


func hace_dano_contacto() -> bool:
	return false
