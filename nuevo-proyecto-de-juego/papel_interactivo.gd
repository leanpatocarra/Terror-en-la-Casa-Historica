extends Area3D

signal documento_recogido

@export var nombre_documento: String = "Documento Confidencial"
@export var contenido_texto: String = "Información sobre el misterio..."

func interactuar() -> void:
	print(">>> [EXITO] ¡La función interactuar() del papel se ejecutó correctamente! <<<")
	
	if get_node_or_null("/root/GlobalLog"):
		GlobalLog.agregar_pista(nombre_documento, contenido_texto)
	else:
		push_warning("GlobalLog no encontrado al guardar pista")
	
	documento_recogido.emit()
	queue_free()
