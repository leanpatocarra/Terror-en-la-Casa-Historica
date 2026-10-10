# cuadro_1.gd
extends Node3D

# Estas variables aparecerán en el Inspector de Godot para que las rellenes a mano
@export var nombre_cuadro: String = "Cuadro Colonial"
@export var codigo_morse: String = ".-"

func interactuar() -> void:
	if codigo_morse != "":
		if get_node_or_null("/root/GlobalLog"):
			# Llamamos a tu función original del Autoload
			GlobalLog.agregar_pista(nombre_cuadro, codigo_morse)
			print("[CÓDIGO REGISTRADO]: ", nombre_cuadro, " -> ", codigo_morse)

# LÍNEA AGREGADA: Si el RayCast toca al hijo StaticBody3D, este llamará al padre automáticamente
func redirigir_interaccion() -> void:
	interactuar()
