class_name CofreBotin
extends StaticBody2D
## Cofre de botín: al abrirlo da piezas al tetris. Se abre golpeándolo con el ataque, por
## contacto o de las dos formas (modos_apertura).
##
## Las piezas viajan por señales: el cofre se lo dice a su Habitacion, esta a la Mazmorra y
## Juego las suma al tetris. Una vez abierto se anota en la celda de su sala, así que al
## volver a la sala aparece abierto y vacío.
##
## Estructura esperada: Sprite (Sprite2D) y CollisionShape2D (rectángulo, si se quiere abrir
## por contacto). Opcional: Provisional (un dibujo de relleno mientras no haya sprites).
## En el editor: capa Muros (1), sin máscara.

## Se emite al abrirse, con las piezas que ha dado.
signal abierto(cantidad: int)

## Lado de la celda en píxeles: el sprite se escala a este tamaño.
const TAM_CELDA := 64.0

const MODO_GOLPE := 1
const MODO_CONTACTO := 2

@export_group("Apertura")
## Cómo se abre: marca Golpe, Contacto o los dos.
@export_flags("Golpe", "Contacto") var modos_apertura := MODO_GOLPE | MODO_CONTACTO
## Solo para el modo Contacto: cuántos píxeles por fuera del cofre se detecta al jugador.
## El cofre es sólido, así que el jugador nunca lo pisa: hace falta algo de margen.
@export var margen_contacto := 4.0

@export_group("Botín")
## Piezas que da. Es el valor que se usa si "usar_rango" está desmarcado.
@export_range(0, 99) var piezas := 3
## Si está marcado, al abrirlo da un número al azar entre piezas_minimas y piezas_maximas
## (los dos incluidos) en vez de "piezas".
@export var usar_rango := false
@export_range(0, 99) var piezas_minimas := 2
@export_range(0, 99) var piezas_maximas := 4

@export_group("Sprites")
@export var sprite_cerrado: Texture2D
@export var sprite_abierto: Texture2D

var esta_abierto := false

var _habitacion: Habitacion
var _zona_contacto: Area2D

@onready var _sprite: Sprite2D = $Sprite
## Dibujo de relleno (opcional): se oculta en cuanto hay sprite_cerrado.
@onready var _provisional: CanvasItem = get_node_or_null("Provisional") as CanvasItem


func _ready() -> void:
	_habitacion = _buscar_habitacion()
	# Ya se abrió en una visita anterior: aparece abierto y vacío, sin dar nada.
	if _habitacion != null and _habitacion.datos != null \
			and _habitacion.datos.cofres_abiertos.has(_clave()):
		esta_abierto = true
		_poner_sprite(true)
		return
	_poner_sprite(false)
	if (modos_apertura & MODO_CONTACTO) != 0:
		_crear_zona_contacto()


## Lo llama el ataque del jugador (ver player.gd).
func recibir_golpe() -> void:
	if (modos_apertura & MODO_GOLPE) != 0:
		_abrir()


func _abrir() -> void:
	if esta_abierto:
		return
	esta_abierto = true
	_poner_sprite(true)
	if _zona_contacto != null:
		_zona_contacto.set_deferred("monitoring", false)

	var cantidad := _calcular_piezas()
	if _habitacion != null:
		_habitacion.registrar_cofre_abierto(_clave())
		_habitacion.entregar_piezas(cantidad)
	abierto.emit(cantidad)


func _calcular_piezas() -> int:
	if usar_rango:
		return randi_range(mini(piezas_minimas, piezas_maximas), maxi(piezas_minimas, piezas_maximas))
	return piezas


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


## Identifica este cofre dentro de su sala: su posición. Cada celda guarda su propia lista.
func _clave() -> Vector2i:
	return Vector2i(global_position.round())


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion


func _poner_sprite(abierto_ahora: bool) -> void:
	var textura := sprite_abierto if abierto_ahora and sprite_abierto != null else sprite_cerrado
	_sprite.texture = textura
	if textura != null:
		_sprite.scale = Vector2.ONE * TAM_CELDA / textura.get_size()
	if _provisional != null:
		_provisional.visible = sprite_cerrado == null
		# Sin sprites, el relleno se atenúa al abrirse para que se note.
		_provisional.modulate = Color(1, 1, 1, 0.4) if abierto_ahora else Color.WHITE
