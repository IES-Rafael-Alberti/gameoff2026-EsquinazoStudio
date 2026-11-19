class_name EnemigoEstados
extends Enemigo
## Enemigo con máquina de estados. Reutiliza todo lo de Enemigo (vida, registro como desafío
## de la sala, daño por contacto, invocado...) y cambia cómo actúa: en cada paso de física
## deja que el estado activo de su MaquinaEstados decida qué hacer.
##
## Estructura de la escena:
##   Enemigo (CharacterBody2D con este script)
##   ├ CollisionShape2D
##   ├ (sprites)
##   ├ AnimationPlayer (opcional): animaciones con el nombre de cada estado (ver Estado)
##   ├ ZonaGolpe (Area2D, opcional): la usa el ataque cuerpo a cuerpo
##   └ MaquinaEstados
##     └ Aparicion, Inactivo, Perseguir, Ataque, Aturdido, VolverASuSitio, Muerte
##       (los que no pongas, no existen: un enemigo sin Ataque no ataca, etc.)
## Los voladores: marcar "volador", capa Enemigos (4), máscara ninguna.
##
## El movimiento lo hacen mover_hacia() y mover(); EnemigoEstadosTerrestre cambia
## mover_hacia() para seguir la malla de navegación.

enum Deteccion { SIEMPRE, RADIO }

## Píxeles por segundo al perseguir y al volver a su sitio.
@export var velocidad := 60.0

@export_group("Detección")
## Siempre: ve al jugador desde que carga la sala. Radio: quieto hasta que entre en
## radio_deteccion.
@export var deteccion := Deteccion.SIEMPRE
## Modo Radio: distancia (píxeles) a la que detecta al jugador.
@export var radio_deteccion := 200.0
## Modo Radio: si cuando el jugador sale del radio deja de perseguir y vuelve a su sitio.
## Desmarcado: una vez que te ha visto, te persigue hasta el final.
@export var perder_al_salir := false

## Dónde estaba al empezar (a donde vuelve en VolverASuSitio).
var posicion_inicial := Vector2.ZERO
var maquina: MaquinaEstados
var reproductor: AnimationPlayer


func _ready() -> void:
	super._ready()
	if is_queued_for_deletion():
		return # sala ya despejada: Enemigo ya lo ha borrado
	_bloqueo = 0.0 # el bloqueo de los invocados lo hace el estado Aparicion
	posicion_inicial = global_position
	reproductor = get_node_or_null("AnimationPlayer") as AnimationPlayer
	maquina = get_node_or_null("MaquinaEstados") as MaquinaEstados
	if maquina == null:
		push_error("El enemigo %s no tiene un hijo MaquinaEstados." % name)
		return
	maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	if maquina == null or maquina.actual == null:
		return
	_enfriamiento = maxf(_enfriamiento - delta, 0.0)
	maquina.fisica(delta)
	if maquina.actual.hace_dano_contacto():
		_aplicar_dano_contacto()


## Daño recibido. "origen" es de dónde viene el golpe (para el retroceso); si no se indica,
## se toma la posición del jugador.
func recibir_dano(cantidad: int, origen := Vector2.INF) -> void:
	if maquina == null or maquina.actual == null or maquina.actual.es_invulnerable():
		return
	vida.recibir_dano(cantidad) # si muere, Enemigo llama a morir()
	if maquina.esta_en(Estado.MUERTE) or not maquina.tiene(Estado.ATURDIDO):
		return
	if origen == Vector2.INF and hay_jugador():
		origen = posicion_jugador()
	maquina.cambiar_a(Estado.ATURDIDO, {"origen": origen})


## En vez de borrarse sin más, pasa al estado Muerte (que se borra al acabar su animación).
func morir() -> void:
	if maquina != null and maquina.tiene(Estado.MUERTE):
		maquina.cambiar_a(Estado.MUERTE)
	else:
		queue_free()


func hay_jugador() -> bool:
	return _jugador() != null


## Centro del jugador, o Vector2.INF si no hay.
func posicion_jugador() -> Vector2:
	var jugador := _jugador()
	if jugador == null:
		return Vector2.INF
	return _posicion_de(jugador)


## Distancia al jugador, o INF si no hay.
func distancia_al_jugador() -> float:
	var destino := posicion_jugador()
	if destino == Vector2.INF:
		return INF
	return global_position.distance_to(destino)


## true si ya ve al jugador según el modo de detección.
func jugador_detectado() -> bool:
	if not hay_jugador():
		return false
	if deteccion == Deteccion.SIEMPRE:
		return true
	return distancia_al_jugador() <= radio_deteccion


## Se mueve hacia un punto a esa velocidad. Los hijos pueden cambiar cómo (rutas...).
func mover_hacia(destino: Vector2, rapidez: float) -> void:
	mover((destino - global_position).normalized() * rapidez)


## Se mueve con esa velocidad exacta.
func mover(nueva_velocidad: Vector2) -> void:
	velocity = nueva_velocidad
	move_and_slide()


func parar() -> void:
	velocity = Vector2.ZERO


## Reproduce la animación si el enemigo tiene AnimationPlayer y existe en él.
func reproducir(nombre: StringName) -> void:
	if reproductor != null and nombre != &"" and reproductor.has_animation(nombre):
		reproductor.play(nombre)
