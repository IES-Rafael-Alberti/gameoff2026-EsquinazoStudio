extends Node2D

@export var Configuracion: Configuracion_Tablero

func _ready():
	$GridBackground.Configuracion = Configuracion
	$FixedBlocks.Configuracion = Configuracion
	$GhostPiece.Configuracion = Configuracion
	$CurrentPiece.Configuracion = Configuracion
	$Tablero.Configuracion = Configuracion
	$"../SidePanel/NextPiece".Configuracion = Configuracion
	$"../ControladorPieza".Configuracion = Configuracion
