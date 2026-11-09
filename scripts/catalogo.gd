class_name Catalogo
extends RefCounted

enum Bioma {MEDIEVAL = 1, HIELO = 2, FUTURISTA = 3 }

const NOMBRES_BIOMA := {
	1: "Medieval",
	2: "Hielo",
	3: "Futurista",
}

const RUTAS_MARCO_BIOMA := {
	1: "res://assets/sprites/piezas/Marco medieval.png",
	2: "",
	3: "",
}

const BIOMA_POR_DEFECTO := 1

static var _cache := {}

static func marco_bioma(nivel: int) -> Texture2D:
	var textura := _cargar(RUTAS_MARCO_BIOMA.get(nivel, ""))
	if textura == null and nivel != BIOMA_POR_DEFECTO:
		textura = _cargar(RUTAS_MARCO_BIOMA.get(BIOMA_POR_DEFECTO, ""))
	return textura

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
