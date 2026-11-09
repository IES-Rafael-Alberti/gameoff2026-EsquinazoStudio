class_name CategoriaSala
extends Resource
## Un tipo de sala (Vacía, Combate, Puzle, Curación, Combate+Puzle...).
## Para añadir uno nuevo: crea un recurso de este tipo y úsalo en los pesos y en los pools.

@export var nombre := ""
## Letra o símbolo corto que se ve provisionalmente en el cuadrado y en la etiqueta.
@export var letra := "?"
## Icono del cuadrado. Si está vacío se muestra la letra.
@export var icono: Texture2D
## Si es true, la sala se marca como resuelta en cuanto el jugador entra (salas vacías).
@export var se_resuelve_al_entrar := false
