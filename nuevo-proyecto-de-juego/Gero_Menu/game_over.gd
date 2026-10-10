extends Control

@onready var boton_reintentar = $Botonera/BtnReintentar
@onready var boton_menu = $Botonera/BtnMenu

# Referencias exactas a tus nodos de sonido hijos
@onready var audio_reintentar: AudioStreamPlayer = $Botonera/BtnReintentar/AudioReintentar
@onready var audio_menu: AudioStreamPlayer = $Botonera/BtnMenu/AudioMenu

func _ready() -> void:
	# Nos aseguramos de que el puntero del mouse sea visible al perder
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Conectamos correctamente los botones con las funciones del script
	boton_reintentar.pressed.connect(_on_reintentar_pressed)
	boton_menu.pressed.connect(_on_menu_pressed)
	
	if audio_reintentar:
		audio_reintentar.autoplay = false
	if audio_menu:
		audio_menu.autoplay = false

func _on_reintentar_pressed() -> void:
	if audio_reintentar:
		audio_reintentar.play()
		# Detiene la ejecución hasta que el sonido termine de sonar
		await audio_reintentar.finished
		
	# Reinicia tu nivel principal
	get_tree().change_scene_to_file("res://escenario pedro/proto2_fusionado.tscn")

func _on_menu_pressed() -> void:
	if audio_menu:
		audio_menu.play()
		# Detiene la ejecución hasta que el sonido termine de sonar
		await audio_menu.finished
		
	# Cambia al menú principal usando tu ruta real que se ve en el árbol de archivos
	get_tree().change_scene_to_file("res://Gero_Menu/menu_principal.tscn")
