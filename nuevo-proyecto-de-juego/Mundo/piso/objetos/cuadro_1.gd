# cuadro_1.gd (Asignado en la raíz de tu cuadro)
extends Node3D

# Estas variables las puedes rellenar a mano desde el Inspector
@export var nombre_cuadro: String = "Cuadro Colonial"
@export var codigo_morse: String = ".-"

# REFERENCIA AL AUDIO: Accedemos al hijo dentro del StaticBody3D
@onready var audio_pista: AudioStreamPlayer3D = get_node_or_null("StaticBody3D/AudioCuadro")

func _ready() -> void:
	if audio_pista:
		audio_pista.autoplay = false

func interactuar() -> void:
	if codigo_morse != "":
		if get_node_or_null("/root/GlobalLog"):
			# Registramos la pista en tu script de Autoload original
			GlobalLog.agregar_pista(nombre_cuadro, codigo_morse)
			
			# REPRODUCCIÓN DEL AUDIO: Ejecuta el efecto posicional 3D
			if audio_pista:
				audio_pista.play()
				print(">>> [AUDIO CUADRO]: Reproduciendo SFX de pista guardada. <<<")
			
			# Mensaje de confirmación detallado en la consola
			print(">>> [LOG DE PISTAS] ¡El jugador tomó el código con éxito! <<<")
			print("    • Objeto Examinado: ", nombre_cuadro)
			print("    • Código Morse Guardado: ", codigo_morse)
			print("-----------------------------------------------------")
