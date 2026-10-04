extends Control
@onready var boton_jugar = $Botonera/BtnJugar
@onready var boton_salir = $Botonera/BtnSalir
func _ready() -> void:
 boton_jugar.pressed.connect(_on_jugar_pressed)
 boton_salir.pressed.connect(_on_salir_pressed)

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://escenario pedro/proto2.tscn")

func _on_salir_pressed() -> void:
	get_tree().quit()
