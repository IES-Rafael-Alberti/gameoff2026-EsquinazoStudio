class_name Capas
extends RefCounted
## Capas de colisión 2D del proyecto, como valores de máscara. Sus nombres también están en
## Project Settings → Layer Names → 2D Physics. Usa siempre estas constantes en el código.
##
## Quién va en cada capa:
##   MUROS:    tiles de las salas y vestíbulos, puertas, pinchos, botón de reinicio
##   JUGADOR:  el jugador
##   CAJAS:    las cajas empujables
##   ENEMIGOS: los enemigos
##   SIERRAS:  las sierras (su zona de daño y, si no son atravesables, su cuerpo)
## Las zonas que solo detectan (placas, zona de entrada, umbral de puerta, zonas de daño)
## no están en ninguna capa: solo tienen máscara para elegir qué detectan.

const MUROS := 1
const JUGADOR := 2
const CAJAS := 4
const ENEMIGOS := 8
const SIERRAS := 16


## true si el nodo es un cuerpo o área que está en alguna de las capas indicadas.
static func esta_en(nodo: Object, capas: int) -> bool:
	return nodo is CollisionObject2D and (nodo.collision_layer & capas) != 0
