extends Node

# Lista donde se guardan los documentos y pistas recolectadas
var lista_pistas: Array[Dictionary] = []

func agregar_pista(nombre: String, texto_o_codigo: String) -> void:
	var nueva_pista = {"nombre": nombre, "contenido": texto_o_codigo}
	if not lista_pistas.has(nueva_pista):
		lista_pistas.append(nueva_pista)
		print("¡Pista guardada en GlobalLog!: ", nombre)
