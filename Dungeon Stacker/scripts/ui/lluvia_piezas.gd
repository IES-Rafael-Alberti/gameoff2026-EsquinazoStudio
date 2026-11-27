extends Node2D
## Lluvia decorativa de piezas de Tetris para el menú principal.
## Hay una cuadrícula de puntos y cada pieza cae encajada en ella, por columnas.

const Piezas = preload("res://scripts/piezas.gd")

@export_range(3, 16, 1) var cantidad := 6
@export_range(16, 128, 1) var tam_celda := 56
@export_range(0.0, 1.0, 0.01) var opacidad := 0.32
@export_range(0.0, 1.0, 0.01) var opacidad_cuadricula := 0.16
## Velocidades en casillas por segundo. Poco rango = flujo continuo, sin rachas.
@export_range(0.5, 10.0, 0.1) var velocidad_min := 2.0
@export_range(0.5, 10.0, 0.1) var velocidad_max := 2.4
## 0 = no giran al caer. Si no, giran 90° cada ese número de segundos.
@export_range(0.0, 8.0, 0.1) var girar_cada := 2.0
## Escala de la cuadrícula en el extremo de arriba (lejos) y en la base (cerca).
## 1 = tamaño normal. Menos de 1 arriba y más de 1 abajo da punto de fuga.
@export_range(0.2, 5.0, 0.01) var escala_arriba := 0.75
@export_range(0.2, 5.0, 0.01) var escala_abajo := 1.30
## Inclinación hacia atrás en grados. 0 = vertical; el signo cambia el lado.
@export_range(-45.0, 45.0, 1.0) var inclinacion := 18.0
## Posición horizontal (0 = izquierda, 1 = derecha) hacia la que convergen las columnas.
@export_range(0.0, 1.0, 0.01) var centro_x := 0.5

class PiezaLluvia:
	var forma: String
	var fase := 0.0
	var columna := 0
	var x := 0.0
	var y := 0.0
	var velocidad := 0.0
	var giros := 0
	var tiempo_giro := 0.0
	var intervalo := 0.0


var _piezas: Array[PiezaLluvia] = []
## Mallas del frame actual: hay que conservarlas hasta que el renderizado las use.
var _mallas_dibujo: Array[ArrayMesh] = []
var _tam_pantalla := Vector2.ZERO
var _tam := 56.0
var _columnas := 0
var _paso := 4


func _ready() -> void:
	_tam_pantalla = get_viewport_rect().size
	var n := maxi(cantidad, 1)
	# La pieza más ancha mide 4 casillas: reservamos 4 columnas por pieza.
	_tam = mini(float(tam_celda), _tam_pantalla.x / (4.0 * float(n)))
	_columnas = maxi(int(_tam_pantalla.x / _tam), 4 * n)
	_paso = maxi(_columnas / n, 4)
	randomize()
	# Carriles y fases se barajan por separado: el orden de entrada no va de un lado a otro.
	var columnas: Array[int] = []
	var fases: Array[float] = []
	for i in n:
		columnas.append(i * _paso)
		fases.append(float(i) / float(n))
	columnas.shuffle()
	fases.shuffle()
	for i in n:
		var pieza := PiezaLluvia.new()
		pieza.columna = columnas[i]
		pieza.fase = fases[i]
		_preparar(pieza, true)
		_piezas.append(pieza)
	queue_redraw()


func _preparar(pieza: PiezaLluvia, inicial := false) -> void:
	pieza.forma = Piezas.FORMAS.keys().pick_random()
	pieza.x = pieza.columna * _tam
	var alto := _alto_celdas(pieza.forma) * _tam
	if inicial:
		# Fases repartidas por la altura útil (ya comprimida), asignadas al azar.
		pieza.y = -alto + pieza.fase * (_alto_util() + 2.0 * alto)
	else:
		# Al reciclar vuelve justo por encima de la pantalla, con un salto mínimo.
		pieza.y = -alto - _tam * randf_range(0.25, 0.75)
	pieza.velocidad = randf_range(velocidad_min, velocidad_max) * _tam
	# Solo orientaciones de Tetris: 0, 1, 2 o 3 giros de 90°.
	pieza.giros = randi_range(0, 3)
	pieza.intervalo = girar_cada * randf_range(0.6, 1.6)
	pieza.tiempo_giro = randf_range(0.0, pieza.intervalo)


func _alto_celdas(forma: String) -> int:
	var alto := 0
	for celda in Piezas.FORMAS[forma]:
		var c: Vector2i = celda
		alto = maxi(alto, maxi(c.x, c.y))
	return alto + 1


## Compresión vertical al inclinar el plano hacia atrás.
func _comprime_y() -> float:
	return maxf(cos(deg_to_rad(inclinacion)), 0.5)


## Deriva horizontal suave de la inclinación.
func _deriva_x() -> float:
	return tan(deg_to_rad(inclinacion)) * 0.5


## Altura en coordenadas sin transformar que ocupa la pantalla ya comprimida.
func _alto_util() -> float:
	return _tam_pantalla.y / _comprime_y()


## Interpola entre la escala de arriba y la de la base.
## Sin clamp: al extrapolar hacia arriba puede anularse y marcar el punto de fuga.
func _escala_perspectiva(y: float) -> float:
	var t := y / maxf(_alto_util(), 1.0)
	return lerpf(escala_arriba, escala_abajo, t)


## Proyección perspectiva: las X convergen hacia el centro al subir.
func _proyectar(p: Vector2) -> Vector2:
	var s := _escala_perspectiva(p.y)
	var cx := centro_x * _tam_pantalla.x
	return Vector2(
		cx + (p.x - cx) * s + p.y * _deriva_x(),
		p.y * _comprime_y()
	)


func _process(delta: float) -> void:
	for pieza in _piezas:
		pieza.y += pieza.velocidad * delta
		if pieza.intervalo > 0.0:
			pieza.tiempo_giro += delta
			if pieza.tiempo_giro >= pieza.intervalo:
				pieza.tiempo_giro -= pieza.intervalo
				pieza.giros = (pieza.giros + 1) % 4
		var y_encajada := floorf(pieza.y / _tam) * _tam
		if y_encajada - _alto_celdas(pieza.forma) * _tam * 0.5 > _alto_util():
			_preparar(pieza)
	queue_redraw()


## Devuelve las casillas ya giradas y normalizadas a enteros desde (0, 0).
## Así cada casilla cae exactamente sobre una intersección de la cuadrícula.
func _celdas_en_rejilla(celdas: Array, giros: int) -> Array[Vector2i]:
	var min_x := 1 << 30
	var min_y := 1 << 30
	for celda in celdas:
		var c: Vector2i = celda
		min_x = mini(min_x, c.x)
		min_y = mini(min_y, c.y)

	var resultado: Array[Vector2i] = []
	for celda in celdas:
		var c: Vector2i = celda
		var x := c.x - min_x
		var y := c.y - min_y
		match giros:
			0: resultado.append(Vector2i(x, y))
			1: resultado.append(Vector2i(-y, x))
			2: resultado.append(Vector2i(-x, -y))
			3: resultado.append(Vector2i(y, -x))

	var nx := 1 << 30
	var ny := 1 << 30
	for c in resultado:
		nx = mini(nx, c.x)
		ny = mini(ny, c.y)
	for i in resultado.size():
		resultado[i] = Vector2i(resultado[i].x - nx, resultado[i].y - ny)
	return resultado


func _dibujar_cuadricula() -> void:
	if opacidad_cuadricula <= 0.0:
		return
	var color := Color(1.0, 1.0, 1.0, opacidad_cuadricula)
	var radio := maxf(1.0, _tam * 0.035)
	# Si arriba se encoge, hay que emitir columnas fuera de pantalla para seguir cubriéndola.
	# Con el centro desplazado, los márgenes izquierdo y derecho ya no son simétricos.
	var s0 := maxf(escala_arriba, 0.05)
	var deriva := absf(_deriva_x()) * _alto_util()
	var cx := centro_x * _tam_pantalla.x
	var x_min := (0.0 - deriva - cx) / s0 + cx
	var x_max := (_tam_pantalla.x + deriva - cx) / s0 + cx
	x_min -= _tam * 2.0
	x_max += _tam * 2.0
	var x := x_min
	while x <= x_max:
		var y := 0.0
		while y <= _alto_util() + _tam:
			var p := _proyectar(Vector2(x, y))
			draw_circle(p, radio * _escala_perspectiva(y), color)
			y += _tam
		x += _tam


## Malla con un quad por casilla. Cada esquina se proyecta por separado,
## así coincide con su punto de la cuadrícula aunque la escala cambie con Y.
func _malla_celdas(posiciones: Array) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for pos in posiciones:
		var p: Vector2 = pos
		var p00 := _proyectar(p)
		var p10 := _proyectar(p + Vector2(_tam, 0.0))
		var p11 := _proyectar(p + Vector2(_tam, _tam))
		var p01 := _proyectar(p + Vector2(0.0, _tam))
		var base := vertices.size()
		vertices.append(Vector3(p00.x, p00.y, 0.0))
		vertices.append(Vector3(p10.x, p10.y, 0.0))
		vertices.append(Vector3(p11.x, p11.y, 0.0))
		vertices.append(Vector3(p01.x, p01.y, 0.0))
		uvs.append(Vector2(0.0, 0.0))
		uvs.append(Vector2(1.0, 0.0))
		uvs.append(Vector2(1.0, 1.0))
		uvs.append(Vector2(0.0, 1.0))
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base)
		indices.append(base + 2)
		indices.append(base + 3)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _draw() -> void:
	_mallas_dibujo.clear()
	_dibujar_cuadricula()
	var color := Color(1.0, 1.0, 1.0, opacidad)
	# Agrupamos por textura para dibujar cada tipo de pieza de una sola pasada.
	var lotes := {}
	for pieza in _piezas:
		var textura := Piezas.TEXTURAS_COLOR.get(pieza.forma) as Texture2D
		if textura == null:
			continue
		if not lotes.has(textura):
			lotes[textura] = []
		var celdas := _celdas_en_rejilla(Piezas.FORMAS[pieza.forma], pieza.giros)
		var y_encajada := floorf(pieza.y / _tam) * _tam
		for celda in celdas:
			lotes[textura].append(Vector2(pieza.x + celda.x * _tam, y_encajada + celda.y * _tam))
	for textura in lotes:
		var tex := textura as Texture2D
		var malla := _malla_celdas(lotes[textura])
		_mallas_dibujo.append(malla)
		draw_mesh(malla, tex, Transform2D.IDENTITY, color)
