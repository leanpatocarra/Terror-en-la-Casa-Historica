extends Area3D

signal documento_recogido

@export var nombre_documento: String = "Documento Confidencial"
@export var contenido_texto: String = "Información sobre el misterio..."

func interactuar() -> void:
	print("--- INTERACCION: Documento tomado ---")

	# 1. Guardar los datos
	if get_node_or_null("/root/GlobalLog"):
		GlobalLog.agregar_pista(nombre_documento, contenido_texto)

	# 2. Avisar que se recogió el papel
	documento_recogido.emit()

	# 3. Activar la niebla del nivel
	var mundo = get_tree().current_scene.find_child(
		"WorldEnvironment", true, false
	)

	if mundo and mundo is WorldEnvironment:
		if mundo.environment:
			mundo.environment.volumetric_fog_enabled = true
			mundo.environment.volumetric_fog_density = 0.027
			print("¡La niebla se ha activado!")
		else:
			push_warning("WorldEnvironment no tiene un recurso Environment.")
	else:
		push_warning("No se encontró el nodo WorldEnvironment.")

	# 4. Eliminar el papel
	queue_free()
