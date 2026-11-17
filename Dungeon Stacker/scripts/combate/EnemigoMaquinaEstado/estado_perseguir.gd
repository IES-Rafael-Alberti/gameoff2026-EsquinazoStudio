class_name EstadoPerseguir
extends Estado
## Va hacia el jugador (en línea recta o por ruta, según el enemigo). Si hay un estado Ataque
## y el jugador está a su alcance, pasa a atacar. Si perder_al_salir está marcado y el jugador
## sale del radio de detección, pasa a VolverASuSitio.


func _init() -> void:
	animacion = &"perseguir"


func fisica(_delta: float) -> void:
	if not enemigo.hay_jugador():
		enemigo.parar()
		return
	var distancia := enemigo.distancia_al_jugador()

	if enemigo.perder_al_salir and enemigo.deteccion == EnemigoEstados.Deteccion.RADIO \
			and distancia > enemigo.radio_deteccion:
		_terminar(VOLVER)
		return

	var ataque := enemigo.maquina.obtener(ATAQUE) as EstadoAtaque
	if ataque != null and ataque.puede_atacar(distancia):
		_terminar(ATAQUE)
		return

	enemigo.mover_hacia(enemigo.posicion_jugador(), enemigo.velocidad)
