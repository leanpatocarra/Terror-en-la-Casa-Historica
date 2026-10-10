# telegrafo_sencillo.gd
extends Node3D

# Escribe aquí en el Inspector los códigos que el jugador debe haber juntado para ganar
@export var codigos_necesarios: Array[String] = [".-", ".--", ".---", ".----"]

func interactuar() -> void:
	print("--- Evaluando códigos en el Telégrafo ---")
	
	if not get_node_or_null("/root/GlobalLog"):
		return
		
	var pistas_recolectadas = GlobalLog.lista_pistas
	var aciertos : int = 0
	
	# Comparamos los códigos guardados en tu Autoload con los requeridos
	for codigo_buscado in codigos_necesarios:
		for pista in pistas_recolectadas:
			if pista["contenido"] == codigo_buscado:
				aciertos += 1
				break 

	# Verificación final de victoria
	if aciertos == codigos_necesarios.size():
		print("¡VICTORIA! Todos los códigos coinciden de forma excelente.")
		# Aquí puedes cargar tu pantalla final:
		# get_tree().change_scene_to_file("res://Gero_Menu/menu_victoria.tscn")
	else:
		print("Faltan pistas en el diario. Códigos correctos: ", aciertos, " de ", codigos_necesarios.size())
