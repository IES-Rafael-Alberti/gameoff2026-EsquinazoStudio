class_name JugadorEstado
extends Node
## Base de los estados del jugador. Cada estado es un nodo hijo de MaquinaEstados (en
## player.tscn) con su propio script, que hereda de esta clase. Solo el estado activo recibe
## fisica() y entrada(). Para cambiar de estado, llama a _terminar() y la máquina hace el cambio.
##
## El nombre del nodo es el nombre del estado: tiene que coincidir con estas constantes.

## Se emite para pedir un cambio de estado. "datos" viaja al estado siguiente (entrar()).
signal terminado(siguiente: StringName, datos: Dictionary)

const INACTIVO := &"Inactivo"
const CAMINAR := &"Caminar"
const ATACAR := &"Atacar"
const HERIDO := &"Herido"
const CAER := &"Caer"
const MUERTE := &"Muerte"
const RESBALAR := &"Resbalar"

## El jugador al que pertenece (lo pone la máquina).
var jugador: Jugador

## Al entrar en el estado. "anterior" es el nombre del estado del que viene.
func entrar(_anterior: StringName, _datos: Dictionary) -> void:
	pass

## Al salir (antes de entrar en el siguiente).
func salir() -> void:
	pass

## Cada paso de física mientras es el estado activo.
func fisica(_delta: float) -> void:
	pass

## Cada evento de entrada mientras es el estado activo.
func entrada(_evento: InputEvent) -> void:
	pass

## Si mientras está activo el jugador no puede recibir daño.
func es_invulnerable() -> bool:
	return false

func _terminar(siguiente: StringName, datos := {}) -> void:
	terminado.emit(siguiente, datos)
