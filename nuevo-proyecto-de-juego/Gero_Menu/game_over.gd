extends Control

@onready var label_puntaje = $Botonera/LabelPuntaje
@onready var boton_reintentar = $Botonera/BtnReintentar
@onready var boton_menu = $Botonera/BtnMenu
func _ready() -> void:
 boton_reintentar.pressed.connect(_on_reintentar_pressed)

func _on_reintentar_pressed() -> void:
 get_tree().change_scene_to_file("res://mundo.tscn")

 
