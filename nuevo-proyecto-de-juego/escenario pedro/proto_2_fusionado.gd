extends Node3D

# Referencias opcionales
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var documento: Area3D = get_node_or_null("papel") # Ajusta el nombre según tu escena
@onready var estatua: CharacterBody3D = get_node_or_null("Estatua") # Ajusta el nombre
@onready var player: CharacterBody3D = get_node_or_null("Player") # Ajusta el nombre

# NUEVAS REFERENCIAS DE AUDIO: Mapeadas al nodo raíz de la escena
@onready var audio_maldicion_1: AudioStreamPlayer = get_node_or_null("AudioMaldicion1")
@onready var audio_maldicion_2: AudioStreamPlayer = get_node_or_null("AudioMaldicion2")

# CERROJO DE SEGURIDAD: Evita que los audios se dupliquen o repitan en bucle
var maldicion_iniciada: bool = false

func _ready() -> void:
	# 1. Aseguramos que la niebla empiece APAGADA al inicio de la partida
	if world_environment and world_environment.environment:
		world_environment.environment.fog_enabled = false
		
	# 2. Conectamos la señal del documento si existe en la escena
	if documento and documento.has_signal("documento_recogido"):
		documento.documento_recogido.connect(_on_documento_recogido)


# LÍNEAS RECUPERADAS: Esta función se ejecutará ÚNICAMENTE cuando el jugador tome el papel
func _on_documento_recogido() -> void:
	print("--- EVENTO INICIADO: Documento recogido ---")
	
	# 1. Encendemos la niebla
	if world_environment and world_environment.environment:
		world_environment.environment.fog_enabled = true
		
	# 2. Activamos la persecución de la estatua
	if estatua and estatua.has_method("activar_estatua"):
		estatua.activar_estatua()
		
	# 3. Activamos el drenaje de sanidad en el jugador
	if player:
		player.evento_activado = true

	# 4. Disparamos la reproducción única de los dos audios en simultáneo
	iniciar_audios_maldicion()


# LÍNEAS RECUPERADAS: Centraliza la ejecución de los sonidos de forma segura
func iniciar_audios_maldicion() -> void:
	# Si el cerrojo ya está activo, salimos inmediatamente para que no suene de nuevo
	if maldicion_iniciada:
		return
		
	maldicion_iniciada = true
	print(">>> [MUNDO AUDIO]: Activando pistas de sonido simultáneas una sola vez. <<<")
	
	if audio_maldicion_1:
		audio_maldicion_1.play()
		
	if audio_maldicion_2:
		audio_maldicion_2.play()
