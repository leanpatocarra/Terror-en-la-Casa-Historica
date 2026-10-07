extends Control

var pause_toggle = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	self.visible = pause_toggle
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("pausa"):
		pause_and_unpause()

func pause_and_unpause():
	pause_toggle = !pause_toggle
	get_tree().paused = pause_toggle
	self.visible = pause_toggle
	
	if pause_toggle:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_btn_jugar_pressed() -> void:
	pause_and_unpause()

func _on_btn_salir_pressed() -> void:
	get_tree().quit()
