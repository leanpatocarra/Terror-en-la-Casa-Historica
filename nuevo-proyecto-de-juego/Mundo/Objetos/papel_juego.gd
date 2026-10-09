extends Area3D

signal documento_recogido

@export var nombre_documento: String = "Documento Confidencial"
@export var contenido_texto: String = "Información sobre el misterio..."

# Función llamada por el Player desde su RayCast3D al presionar 'E'
func interactuar() -> void:
	print("--- INTERACCION: Documento tomado ---")
	
	# 1. Guardar datos en el Autoload Global
	if get_node_or_null("/root/GlobalLog"):
		GlobalLog.agregar_pista(nombre_documento, contenido_texto)
	
	# 2. Avisar al mapa que se recogió el papel
	documento_recogido.emit()
	
	# 3. Eliminar el papel del escenario
	queue_free()
