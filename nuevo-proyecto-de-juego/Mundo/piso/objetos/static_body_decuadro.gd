# puente_colision.gd
extends StaticBody3D

func interactuar() -> void:
	# Le avisa al nodo padre (el cuadro principal) que ejecute su código
	if get_parent() and get_parent().has_method("interactuar"):
		get_parent().interactuar()
