class_name TrampaGiratoria
extends Peligro
## Trampa giratoria: un centro fijo y sólido del que salen N palos a ángulos iguales que
## giran sin parar y sin que nada los frene (atraviesan muros, cajas y lo que sea).
## Los palos dañan al jugador y a los enemigos que andan; el centro bloquea pero no daña.
## En el editor: capa ninguna, máscara Jugador + Enemigos (como cualquier Peligro).
## Los palos se construyen al ejecutar, así que en el editor solo se ve el cuerpo del centro.
##
## Si tiene un hijo NavigationObstacle2D, su radio se ajusta solo al alcance de los palos
## más un margen, para que los enemigos que andan esquiven todo el círculo que barren.

@export_group("Palos")
## Palos repartidos a ángulos iguales: 2 = uno cada 180°, 3 = uno cada 120°...
@export_range(1, 12) var cantidad_palos := 2
## Piezas de cada palo sin contar el centro: la última es la punta y el resto, intermedias.
## Longitud 5 = 4 intermedios + la punta.
@export_range(1, 20) var longitud := 3
## Distancia entre los centros de dos piezas seguidas (píxeles). Para que se toquen, igual
## al tamaño visible de la pieza.
@export var separacion_piezas := 64.0
## Ancho de la zona que hace daño a lo largo del palo (píxeles).
@export var grosor_dano := 24.0

@export_group("Giro")
## Grados por segundo. Negativo gira en sentido contrario. Siempre a velocidad constante.
@export var velocidad_giro := 90.0
## Ángulo con el que empieza, en grados.
@export var angulo_inicial := 0.0
## Segundos que tarda en empezar a girar tras aparecer. 0 = gira al instante.
## Durante el retardo se queda quieta, pero sigue haciendo daño al tocarla.
@export var retardo_activacion := 0.0

@export_group("Navegación")
## Píxeles que se suman al alcance de los palos para el radio del NavigationObstacle2D.
## Tiene que cubrir al menos el cuerpo del enemigo (16 px) más un poco de holgura.
@export var margen_obstaculo := 32.0

@export_group("Sprites")
@export var sprite_centro: Texture2D
@export var sprite_intermedio: Texture2D
@export var sprite_punta: Texture2D
## Escala de los sprites (0.125 para arte de 512 px en casillas de 64).
@export var escala_sprites := 0.125

var _angulo := 0.0 # radianes
var _tiempo_para_girar := 0.0 # segundos que faltan para empezar a girar
var _brazos: Node2D # contiene los sprites de los palos y del centro; es lo que gira
var _zonas: Array[CollisionShape2D] = []
var _desfases: Array[float] = [] # ángulo de cada palo respecto al giro general
var _distancia_zona := 0.0 # del centro al medio de la zona de daño de un palo


func _ready() -> void:
	super._ready()
	_angulo = deg_to_rad(angulo_inicial)
	_tiempo_para_girar = maxf(retardo_activacion, 0.0)
	_construir()
	_ajustar_obstaculo()
	_aplicar_giro()


func _physics_process(delta: float) -> void:
	super._physics_process(delta) # daño por contacto, también durante el retardo
	if _tiempo_para_girar > 0.0:
		_tiempo_para_girar -= delta
		return
	_angulo += deg_to_rad(velocidad_giro) * delta
	_aplicar_giro()


## Crea los palos (sprites y zonas de daño) y el sprite del centro.
func _construir() -> void:
	_brazos = Node2D.new()
	add_child(_brazos)

	var palos := maxi(cantidad_palos, 1)
	var largo := maxi(longitud, 1)
	# La zona de un palo va desde el borde del centro hasta el final de la punta.
	_distancia_zona = (largo + 1) * separacion_piezas / 2.0

	for i in palos:
		var desfase := TAU * i / palos
		_desfases.append(desfase)

		var palo := Node2D.new()
		palo.rotation = desfase
		_brazos.add_child(palo)
		for j in range(1, largo + 1):
			var punta := j == largo
			palo.add_child(_crear_pieza(
				sprite_punta if punta else sprite_intermedio,
				Vector2(j * separacion_piezas, 0.0),
				Vector2(separacion_piezas, grosor_dano),
				Color(0.9, 0.2, 0.2) if punta else Color(0.7, 0.7, 0.7)))

		# Una CollisionShape2D solo funciona como hija directa del Area2D: se coloca y
		# se gira a mano en _aplicar_giro().
		var forma := RectangleShape2D.new()
		forma.size = Vector2(largo * separacion_piezas, grosor_dano)
		var zona := CollisionShape2D.new()
		zona.shape = forma
		add_child(zona)
		_zonas.append(zona)

	# El centro gira con los palos y se dibuja encima de ellos.
	_brazos.add_child(_crear_pieza(sprite_centro, Vector2.ZERO,
			Vector2.ONE * 56.0, Color(0.25, 0.25, 0.3)))


## Ajusta el radio del obstáculo de navegación (si lo hay): del centro al borde exterior de
## la punta (lo que barren los palos) más margen_obstaculo.
func _ajustar_obstaculo() -> void:
	var obstaculo := get_node_or_null("NavigationObstacle2D") as NavigationObstacle2D
	if obstaculo == null:
		return
	var alcance := maxi(longitud, 1) * separacion_piezas + separacion_piezas / 2.0
	obstaculo.radius = alcance + margen_obstaculo


## Pone los sprites y las zonas de daño en el ángulo actual.
func _aplicar_giro() -> void:
	_brazos.rotation = _angulo
	for i in _zonas.size():
		var angulo := _angulo + _desfases[i]
		_zonas[i].rotation = angulo
		_zonas[i].position = Vector2.from_angle(angulo) * _distancia_zona


## Un sprite, o un rectángulo de color si todavía no hay textura.
func _crear_pieza(textura: Texture2D, posicion: Vector2, tamano_marcador: Vector2,
		color: Color) -> Node2D:
	if textura != null:
		var sprite := Sprite2D.new()
		sprite.texture = textura
		sprite.scale = Vector2.ONE * escala_sprites
		sprite.position = posicion
		return sprite
	var mitad := tamano_marcador / 2.0
	var marcador := Polygon2D.new()
	marcador.polygon = PackedVector2Array([
		-mitad, Vector2(mitad.x, -mitad.y), mitad, Vector2(-mitad.x, mitad.y)])
	marcador.color = color
	marcador.position = posicion
	return marcador
