extends Control

var pause_toggle := false

@onready var boton_jugar: Button = $VBoxContainer/BtnJugar
@onready var boton_salir: Button = $VBoxContainer/BtnSalir
@onready var audio_reanudar: AudioStreamPlayer = $VBoxContainer/BtnJugar/AudioReanudar
@onready var audio_salir: AudioStreamPlayer = $VBoxContainer/BtnSalir/AudioSalir

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	# Asegúrate de NO tener aquí la línea Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	boton_jugar.pressed.connect(_on_btn_jugar_pressed)
	boton_salir.pressed.connect(_on_btn_salir_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape") and not event.is_echo():
		pause_and_unpause()

func pause_and_unpause() -> void:
	pause_toggle = not pause_toggle
	get_tree().paused = pause_toggle
	visible = pause_toggle

	if pause_toggle:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_btn_jugar_pressed() -> void:
	if audio_reanudar.stream:
		audio_reanudar.play()
		await audio_reanudar.finished

	pause_and_unpause()

func _on_btn_salir_pressed() -> void:
	if audio_salir.stream:
		audio_salir.play()
		await audio_salir.finished

	get_tree().quit()
