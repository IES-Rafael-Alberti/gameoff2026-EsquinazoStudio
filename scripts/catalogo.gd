class_name Catalogo
extends RefCounted

const NOMBRES_CATEGORIA := ["A", "B", "C", "D", "E", "F"]

const RUTAS_ICONO_CATEGORIA := {
	0: "", # A
	1: "", # B
	2: "", # C
	3: "", # D
	4: "", # E
	5: "", # F
}

const RUTAS_MARCO_NIVEL := {
	1: "res://assets/sprites/piezas/Marco medieval.png",
	2: "", # futuro: hielo
	3: "", # futuro: futurista
}

const NIVEL_POR_DEFECTO := 1

static var _cache := {}

static func icono_categoria(categoria: int) -> Texture2D:
	return _cargar(RUTAS_ICONO_CATEGORIA.get(categoria, ""))

static func marco_nivel(nivel: int) -> Texture2D:
	var textura := _cargar(RUTAS_MARCO_NIVEL.get(nivel, ""))
	if textura == null and nivel != NIVEL_POR_DEFECTO:
		textura = _cargar(RUTAS_MARCO_NIVEL.get(NIVEL_POR_DEFECTO, ""))
	return textura

static func letra_categoria(categoria: int) -> String:
	if categoria >= 0 and categoria < NOMBRES_CATEGORIA.size():
		return NOMBRES_CATEGORIA[categoria]
	return "?"

static func _cargar(ruta: String) -> Texture2D:
	if ruta.is_empty():
		return null
	if _cache.has(ruta):
		return _cache[ruta]
	var textura: Texture2D = null
	if ResourceLoader.exists(ruta):
		var recurso = load(ruta)
		if recurso is Texture2D:
			textura = recurso
	_cache[ruta] = textura
	return textura
