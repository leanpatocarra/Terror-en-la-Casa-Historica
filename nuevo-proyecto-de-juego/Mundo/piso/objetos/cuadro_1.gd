# cuadro_1.gd
extends Node3D

# Estas variables las rellenas desde el Inspector de Godot
@export var nombre_cuadro: String = "Cuadro Colonial"
@export var codigo_morse: String = ".-"

func interactuar() -> void:
	if codigo_morse != "":
		if get_node_or_null("/root/GlobalLog"):
			# Registramos la pista en tu script de Autoload original
			GlobalLog.agregar_pista(nombre_cuadro, codigo_morse)
			
			# AGREGADO: Mensaje de confirmación detallado en la consola
			print(">>> [LOG DE PISTAS] ¡El jugador tomó el código con éxito! <<<")
			print("    • Objeto Examinado: ", nombre_cuadro)
			print("    • Código Morse Guardado: ", codigo_morse)
			print("-----------------------------------------------------")
