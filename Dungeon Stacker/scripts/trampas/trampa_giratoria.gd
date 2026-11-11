class_name TrampaGiratoria
extends Peligro
## Trampa giratoria: un centro fijo y sólido del que salen N palos a ángulos iguales que
## giran sin parar y sin que nada los frene (atraviesan muros, cajas y lo que sea).
## Los palos dañan al jugador y a los enemigos que andan; el centro bloquea pero no daña.
## En el editor: capa ninguna, máscara Jugador + Enemigos (como cualquier Peligro).
## Los palos se construyen al ejecutar, así que en el editor solo se ve el centro.

## Lado de la casilla en píxeles: cada pieza del palo ocupa una casilla.
const TAM_CELDA := 64.0

@export_group("Palos")
## Palos repartidos a ángulos iguales: 2 = uno cada 180°, 3 = uno cada 120°...
@export_range(1, 12) var cantidad_palos := 2
## Casillas de cada palo sin contar el centro: la última es la punta y el resto, intermedios.
## Longitud 5 = 4 intermedios + la punta.
@export_range(1, 20) var longitud := 3
## Ancho de la zona que hace daño a lo largo del palo (píxeles).
@export var grosor_dano := 24.0

@export_group("Giro")
## Grados por segundo. Negativo gira en sentido contrario. Siempre a velocidad constante.
@export var velocidad_giro := 90.0
## Ángulo con el que empieza, en grados.
@export var angulo_inicial := 0.0

@export_group("Sprites")
@export var sprite_centro: Texture2D
@export var sprite_intermedio: Texture2D
@export var sprite_punta: Texture2D
## Grados que hay que girar los sprites del palo para que apunten hacia la derecha.
## Si los dibujaste apuntando hacia arriba, 90.
@export var rotacion_sprites := 0.0

var _brazos: Node2D


func _ready() -> void:
	super._ready()
	_construir()


func _physics_process(delta: float) -> void:
	super._physics_process(delta) # daño por contacto
	_brazos.rotation += deg_to_rad(velocidad_giro) * delta


## Crea los palos (sprites y zonas de daño) y el sprite del centro.
func _construir() -> void:
	_brazos = Node2D.new()
	_brazos.rotation = deg_to_rad(angulo_inicial)
	add_child(_brazos)

	var palos := maxi(cantidad_palos, 1)
	var largo := maxi(longitud, 1)
	for i in palos:
		var palo := Node2D.new()
		palo.rotation = TAU * i / palos
		_brazos.add_child(palo)

		# El palo ocupa desde el borde del centro (x = 32) hasta largo casillas más allá.
		for j in range(1, largo + 1):
			var punta := j == largo
			palo.add_child(_crear_pieza(
				sprite_punta if punta else sprite_intermedio,
				Vector2(j * TAM_CELDA, 0.0),
				Vector2(TAM_CELDA, grosor_dano),
				deg_to_rad(rotacion_sprites),
				Color(0.9, 0.2, 0.2) if punta else Color(0.7, 0.7, 0.7)))

		var zona := CollisionShape2D.new()
		var forma := RectangleShape2D.new()
		forma.size = Vector2(largo * TAM_CELDA, grosor_dano)
		zona.shape = forma
		zona.position = Vector2(largo * TAM_CELDA / 2.0 + TAM_CELDA / 2.0, 0.0)
		palo.add_child(zona)

	# El centro se dibuja encima de los palos y no gira.
	add_child(_crear_pieza(sprite_centro, Vector2.ZERO, Vector2.ONE * 56.0, 0.0, Color(0.25, 0.25, 0.3)))


## Un sprite de una casilla, o un rectángulo de color si todavía no hay textura.
func _crear_pieza(textura: Texture2D, posicion: Vector2, tamano_marcador: Vector2,
		rotacion: float, color: Color) -> Node2D:
	if textura != null:
		var sprite := Sprite2D.new()
		sprite.texture = textura
		sprite.scale = Vector2.ONE * TAM_CELDA / textura.get_size()
		sprite.rotation = rotacion
		sprite.position = posicion
		return sprite
	var mitad := tamano_marcador / 2.0
	var marcador := Polygon2D.new()
	marcador.polygon = PackedVector2Array([
		-mitad, Vector2(mitad.x, -mitad.y), mitad, Vector2(-mitad.x, mitad.y)])
	marcador.color = color
	marcador.position = posicion
	return marcador
