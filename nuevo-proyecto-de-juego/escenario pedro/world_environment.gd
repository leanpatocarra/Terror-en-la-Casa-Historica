extends WorldEnvironment


func _ready() -> void:
	add_to_group("ambiente")

func activar_niebla() -> void:
	if environment == null:
		return

	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.08

	print("La niebla ha comenzado...")
