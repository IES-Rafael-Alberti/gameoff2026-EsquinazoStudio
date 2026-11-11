class_name CofreFalso
extends StaticBody2D
## Cofre trampa. Se abre golpeándolo con el ataque, por contacto o de las dos
## formas (modos_apertura), y al abrirse aparece un enemigo.
##
## La escena del enemigo se elige en el inspector (escena_enemigo). Si se deja vacía sale uno
## provisional, así la trampa se puede montar y probar sin esperar al dibujante.
##
## Sala sin despejar: el enemigo es un desafío más (las puertas se cierran hasta matarlo).
## Sala ya despejada: no cuenta como desafío y desaparece al salir de la sala.
## Al aparecer el enemigo se queda bloqueado un momento (ver bloqueo_invocado en enemigo.gd).

## Lado de la celda en píxeles: el sprite se escala a este tamaño.
const TAM_CELDA := 64.0
## Enemigo de relleno mientras no haya uno propio.
const ENEMIGO_PROVISIONAL := preload("res://scenes/enemigos/EnemigoPerseguidor.tscn")

const MODO_GOLPE := 1
const MODO_CONTACTO := 2

@export_group("Apertura")
## Cómo se abre: marca Golpe, Contacto o los dos.
@export_flags("Golpe", "Contacto") var modos_apertura := MODO_GOLPE | MODO_CONTACTO
## Solo para el modo Contacto: cuántos píxeles por fuera del cofre se detecta al jugador.
## El cofre es sólido, así que el jugador nunca lo pisa: hace falta algo de margen.
@export var margen_contacto := 4.0

@export_group("Enemigo")
## Enemigo que sale al abrirlo. Su escena debe tener un Enemigo como nodo raíz.
## Vacío = enemigo provisional.
@export var escena_enemigo: PackedScene
## Dónde aparece respecto al cofre, en píxeles.
@export var desfase_aparicion := Vector2.ZERO
## Segundos entre la apertura y la aparición (para dar tiempo a una animación de apertura).
@export var retardo_aparicion := 0.0

@export_group("Sprites")
@export var sprite_cerrado: Texture2D
@export var sprite_abierto: Texture2D

var abierto := false

var _zona_contacto: Area2D

@onready var _sprite: Sprite2D = $Sprite
## Dibujo de relleno (opcional): se oculta en cuanto hay sprite_cerrado.
@onready var _provisional: CanvasItem = get_node_or_null("Provisional") as CanvasItem


func _ready() -> void:
	_poner_sprite(false)
	if (modos_apertura & MODO_CONTACTO) != 0:
		_crear_zona_contacto()


## Lo llama el ataque del jugador (ver player.gd).
func recibir_golpe() -> void:
	if (modos_apertura & MODO_GOLPE) != 0:
		_abrir()


func _abrir() -> void:
	if abierto:
		return
	abierto = true
	_poner_sprite(true)
	if _zona_contacto != null:
		_zona_contacto.set_deferred("monitoring", false)
	# Tras abrirse ya no estorba: el enemigo sale justo encima y no debe quedarse atrapado.
	for hijo in get_children():
		if hijo is CollisionShape2D:
			hijo.set_deferred("disabled", true)
	if retardo_aparicion > 0.0:
		await get_tree().create_timer(retardo_aparicion).timeout
		if not is_inside_tree():
			return
	_invocar_enemigo()


## Zona algo mayor que el cofre que detecta al jugador (modo Contacto).
func _crear_zona_contacto() -> void:
	for hijo in get_children():
		if not hijo is CollisionShape2D:
			continue
		var forma := hijo.shape as RectangleShape2D
		if forma == null:
			push_warning("El modo Contacto del cofre %s necesita un CollisionShape2D rectangular." % name)
			return
		var zona_forma := RectangleShape2D.new()
		zona_forma.size = forma.size + Vector2.ONE * margen_contacto * 2.0
		var colision := CollisionShape2D.new()
		colision.shape = zona_forma
		colision.position = hijo.position
		_zona_contacto = Area2D.new()
		_zona_contacto.collision_layer = 0
		_zona_contacto.collision_mask = Capas.JUGADOR
		_zona_contacto.add_child(colision)
		add_child(_zona_contacto)
		_zona_contacto.body_entered.connect(_on_cuerpo_entro)
		return
	push_warning("El cofre %s no tiene ningún CollisionShape2D: no se podrá abrir por contacto." % name)

func _on_cuerpo_entro(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("jugador"):
		_abrir()

func _invocar_enemigo() -> void:
	var escena := escena_enemigo if escena_enemigo != null else ENEMIGO_PROVISIONAL
	var nodo := escena.instantiate()
	var enemigo := nodo as Enemigo
	if enemigo == null:
		push_error("La escena del cofre falso debe tener un Enemigo como nodo raíz.")
		nodo.queue_free()
		return
	enemigo.invocado = true
	# Mismo padre que el cofre, así sus coordenadas locales coinciden.
	enemigo.position = position + desfase_aparicion
	get_parent().add_child.call_deferred(enemigo)

func _poner_sprite(esta_abierto: bool) -> void:
	var textura := sprite_abierto if esta_abierto else sprite_cerrado
	if textura == null:
		textura = sprite_cerrado
	_sprite.texture = textura
	if textura != null:
		_sprite.scale = Vector2.ONE * TAM_CELDA / textura.get_size()
	if _provisional != null:
		_provisional.visible = sprite_cerrado == null
		# Sin sprites, el relleno se atenúa al abrirse para que se note.
		_provisional.modulate = Color(1, 1, 1, 0.4) if esta_abierto else Color.WHITE
