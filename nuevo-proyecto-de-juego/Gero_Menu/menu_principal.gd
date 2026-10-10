extends Control

@onready var boton_jugar = $Botonera/BtnJugar
@onready var boton_salir = $Botonera/BtnSalir

# Obtenemos los audios que están dentro de cada botón de tu árbol
@onready var audio_jugar: AudioStreamPlayer = $Botonera/BtnJugar/AudioJugar
@onready var audio_salir: AudioStreamPlayer = $Botonera/BtnSalir/AudioSalir
@onready var audio_Menu: AudioStreamPlayer = $AudioAmbiente

func _ready() -> void:
	# Conectamos las señales a las funciones correctas con el guion bajo inicial
	boton_jugar.pressed.connect(_on_jugar_pressed)
	boton_salir.pressed.connect(_on_salir_pressed)
	
	if audio_jugar:
		audio_jugar.autoplay = false
	if audio_salir:
		audio_salir.autoplay = false

func _on_jugar_pressed() -> void:
	if audio_jugar:
		audio_jugar.play()
		# Esperamos que termine de sonar el audio del botón jugar
		await audio_jugar.finished
		
	# Cambiamos a la escena del nivel (con la ruta corregida a proto2_fusionado)
	get_tree().change_scene_to_file("res://escenario pedro/proto2_fusionado.tscn")

func _on_salir_pressed() -> void:
	if audio_salir:
		audio_salir.play()
		# Esperamos que termine de sonar el audio del botón salir
		await audio_salir.finished
		
	# Cerramos el juego de forma segura
	get_tree().quit()
