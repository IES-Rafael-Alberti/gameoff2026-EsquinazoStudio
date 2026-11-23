class_name JugadorHerido
extends JugadorEstado
## Retroceso tras un golpe: no se controla al personaje mientras dura. Al acabar vuelve a
## Inactivo. Reproduce "Hurt_<dirección>" si existe esa animación.


func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	jugador.animar("Hurt")


func fisica(delta: float) -> void:
	if not jugador.avanzar_retroceso(delta):
		_terminar(INACTIVO)
