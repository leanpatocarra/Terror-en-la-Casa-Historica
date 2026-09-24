extends Node3D

var sensibilidad = 0.1
var vision_point= 0
var rotacion_horizontal = 0.0
var rotacion_vertical = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:

		# ROTACIÓN HORIZONTAL — EJE Y
		rotacion_horizontal += -event.relative.x * sensibilidad
		get_parent().rotation.y = deg_to_rad(rotacion_horizontal)

		# ROTACIÓN VERTICAL — EJE X
		rotacion_vertical += -event.relative.y * sensibilidad
		rotacion_vertical = clampf(rotacion_vertical,-90.0,90.0)

		rotation.x = deg_to_rad(rotacion_vertical)
