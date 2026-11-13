class_name Minimapa
extends Control

const SEPARACION := 2.0

const COLOR_FONDO := Color(0.05, 0.05, 0.08, 0.82)
const COLOR_BORDE := Color(0.85, 0.85, 0.9, 0.9)
const COLOR_PENDIENTE := Color(0.95, 0.65, 0.15, 0.9)
const COLOR_RESUELTA := Color(0.20, 0.75, 0.35, 0.9)
const COLOR_ACTUAL := Color(1, 1, 1, 1)
const COLOR_LETRA := Color(1, 1, 1, 1)
const ESPACIO_VESTIBULO := 12.0
const COLOR_VESTIBULO := Color(0.55, 0.75, 1.0, 0.9)

## Distancia (píxeles) del minimapa al borde superior derecho de la pantalla.
@export var margen := 24.0
## Lado máximo (píxeles) que puede ocupar la rejilla, en su dimensión mayor.
@export var tam_maximo := 480.0
## Lado mínimo de cada casilla del minimapa (píxeles).
@export var tam_min_celda := 10.0
## Lado máximo de cada casilla del minimapa (píxeles).
@export var tam_max_celda := 48.0

var mazmorra: Mazmorra

var _tam_celda := 0.0
var _ancho := 0.0
var _alto := 0.0
var _origen := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func configurar(p_mazmorra: Mazmorra) -> void:
	mazmorra = p_mazmorra
	refrescar()


func refrescar() -> void:
	_recalcular_tamano()
	queue_redraw()


func _recalcular_tamano() -> void:
	if mazmorra == null or mazmorra._columnas <= 0 or mazmorra._filas <= 0:
		_ancho = 0.0
		_alto = 0.0
		return

	var mayor := maxi(mazmorra._columnas, mazmorra._filas)
	var disponible := tam_maximo - SEPARACION * 2.0
	_tam_celda = clampf(
		floorf((disponible - SEPARACION * (mayor - 1)) / mayor),
		tam_min_celda,
		tam_max_celda
	)
	_ancho = mazmorra._columnas * _tam_celda + SEPARACION * (mazmorra._columnas + 1)
	var alto_rejilla := mazmorra._filas * _tam_celda + SEPARACION * (mazmorra._filas + 1)
	_alto = alto_rejilla + ESPACIO_VESTIBULO * 2.0
	_origen = Vector2(SEPARACION, SEPARACION + ESPACIO_VESTIBULO)

	offset_left = -margen - _ancho
	offset_right = -margen
	offset_top = margen
	offset_bottom = margen + _alto


func _draw() -> void:
	if mazmorra == null or _ancho <= 0.0:
		return

	draw_rect(Rect2(Vector2.ZERO, Vector2(_ancho, _alto)), COLOR_FONDO, true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(_ancho, _alto)), COLOR_BORDE, false, 2.0)

	for y in mazmorra._filas:
		for x in mazmorra._columnas:
			var celda := Vector2i(x, y)
			if not mazmorra.celdas.has(celda):
				continue
			var datos: CeldaTablero = mazmorra.celdas[celda]
			var pos := _origen + Vector2(x, y) * (_tam_celda + SEPARACION)
			var rect := Rect2(pos, Vector2(_tam_celda, _tam_celda))
			draw_rect(rect, COLOR_RESUELTA if datos.resuelta else COLOR_PENDIENTE, true)
			_dibujar_categoria(rect, datos.categoria)
			if mazmorra.lugar == Mazmorra.Lugar.SALA and celda == mazmorra.celda_actual:
				draw_rect(rect, COLOR_ACTUAL, false, 3.0)
	_dibujar_vestibulos()


func _dibujar_categoria(rect: Rect2, categoria: CategoriaSala) -> void:
	if categoria == null:
		return

	if categoria.icono != null:
		var medida := categoria.icono.get_size()
		if medida.x > 0.0 and medida.y > 0.0:
			var escala := minf(rect.size.x / medida.x, rect.size.y / medida.y) * 0.7
			var tam := medida * escala
			draw_texture_rect(categoria.icono, Rect2(rect.position + (rect.size - tam) * 0.5, tam), false)
		return

	var fuente := get_theme_default_font()
	var tam_fuente := int(_tam_celda * (0.55 if categoria.letra.length() <= 1 else 0.42))
	var ancho := fuente.get_string_size(categoria.letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_fuente).x
	var pos := rect.position + Vector2(
		(rect.size.x - ancho) * 0.5,
		rect.size.y * 0.5 + tam_fuente * 0.35
	)
	draw_string_outline(fuente, pos, categoria.letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_fuente, 3, Color.BLACK)
	draw_string(fuente, pos, categoria.letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_fuente, COLOR_LETRA)

func _dibujar_vestibulos() -> void:
	var paso := _tam_celda + SEPARACION
	for x in mazmorra._columnas:
		var centro_x := _origen.x + x * paso + _tam_celda * 0.5

		if mazmorra.hay_habitacion(Vector2i(x, 0)):
			_dibujar_chevron(
				Vector2(centro_x, _origen.y - ESPACIO_VESTIBULO * 0.5),
				true,
				COLOR_VESTIBULO
			)

		if mazmorra.hay_habitacion(Vector2i(x, mazmorra._filas - 1)):
			var y := _origen.y + mazmorra._filas * paso - SEPARACION + ESPACIO_VESTIBULO * 0.5
			_dibujar_chevron(Vector2(centro_x, y), false, COLOR_VESTIBULO)

	if mazmorra.lugar == Mazmorra.Lugar.VESTIBULO_INFERIOR or mazmorra.lugar == Mazmorra.Lugar.VESTIBULO_SUPERIOR:
		var columna := clampi(mazmorra.columna_vestibulo, 0, mazmorra._columnas - 1)
		if mazmorra.columna_vestibulo < 0:
			columna = int(mazmorra._columnas / 2.0)
		var centro_x := _origen.x + columna * paso + _tam_celda * 0.5
		var y := _origen.y - ESPACIO_VESTIBULO * 0.5
		if mazmorra.lugar == Mazmorra.Lugar.VESTIBULO_INFERIOR:
			y = _origen.y + mazmorra._filas * paso - SEPARACION + ESPACIO_VESTIBULO * 0.5
		draw_circle(Vector2(centro_x, y), maxf(_tam_celda * 0.16, 2.0), COLOR_ACTUAL)


func _dibujar_chevron(centro: Vector2, hacia_arriba: bool, color: Color) -> void:
	var d := _tam_celda * 0.22
	var puntos := PackedVector2Array()
	if hacia_arriba:
		puntos.append(centro + Vector2(-d, d * 0.5))
		puntos.append(centro + Vector2(d, d * 0.5))
		puntos.append(centro + Vector2(0, -d * 0.5))
	else:
		puntos.append(centro + Vector2(-d, -d * 0.5))
		puntos.append(centro + Vector2(d, -d * 0.5))
		puntos.append(centro + Vector2(0, d * 0.5))
	draw_colored_polygon(puntos, color)
