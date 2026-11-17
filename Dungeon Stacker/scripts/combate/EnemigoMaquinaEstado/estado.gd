class_name Estado
extends Node
## Base de los estados de un enemigo (EnemigoEstados). Cada estado es un nodo hijo de
## MaquinaEstados con su propio script que hereda de esta clase. Solo el estado activo recibe
## fisica(); cuando quiere cambiar de estado llama a _terminar() y la máquina hace el cambio.
##
## El nombre del nodo es el nombre del estado: los de abajo son los que usa el código.

## Se emite para pedir un cambio de estado. "datos" viaja al estado siguiente (entrar()).
signal terminado(siguiente: StringName, datos: Dictionary)

const APARICION := &"Aparicion"
const INACTIVO := &"Inactivo"
const PERSEGUIR := &"Perseguir"
const ATAQUE := &"Ataque"
const ATURDIDO := &"Aturdido"
const VOLVER := &"VolverASuSitio"
const MUERTE := &"Muerte"

## Animación del AnimationPlayer del enemigo que se reproduce al entrar en este estado.
## Vacío, o una que no exista en el AnimationPlayer = no hace nada.
@export var animacion: StringName = &""

## Lo pone la máquina al arrancar.
var enemigo: EnemigoEstados


## Al pasar a ser el estado activo. "anterior" es el nombre del estado que había.
func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	pass


## Justo antes de dejar de ser el estado activo (limpieza).
func salir() -> void:
	pass


## Cada paso de física mientras es el estado activo.
func fisica(_delta: float) -> void:
	pass


## true: el enemigo no recibe daño en este estado.
func es_invulnerable() -> bool:
	return false


## false: el enemigo no hace daño por contacto en este estado.
func hace_dano_contacto() -> bool:
	return true


func _terminar(siguiente: StringName, datos := {}) -> void:
	terminado.emit(siguiente, datos)
