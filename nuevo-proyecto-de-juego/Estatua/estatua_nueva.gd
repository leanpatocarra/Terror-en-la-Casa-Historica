extends CharacterBody3D

# --- CONFIGURACIÓN DE MOVIMIENTO ---
@export var SPEED: float = 15.0
const GRAVITY: float = 9.8

# --- REFERENCIAS A NODOS INTERNOS CORREGIDAS ---
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Nodos de sonido mapeados según la jerarquía de tu escena
@onready var audio_voz: AudioStreamPlayer3D = get_node_or_null("AudioVoz")
@onready var audio_pasos: AudioStreamPlayer3D = get_node_or_null("AudioPasos")

# --- REFERENCIA AL JUGADOR ---
var player: CharacterBody3D = null

# --- ESTADO DE VISIÓN ---
var jugador_mirando: bool = false

# --- ESTADO DE ACTIVACIÓN ---
var esta_activa: bool = false

# Control interno para que la voz no se reproduzca en bucle continuo
var ya_hablo: bool = false

func _ready() -> void:
	# Verificación del AnimationPlayer en consola al arrancar
	if anim_player:
		print("AnimationPlayer encontrado: ", anim_player.get_path())
		print("Animaciones disponibles: ", anim_player.get_animation_list())
	else:
		push_error("No se encontró el AnimationPlayer de la nueva estatua")
		
	# Desactivamos reproducción automática para controlarlos por script
	if audio_voz:
		audio_voz.autoplay = false
	if audio_pasos:
		audio_pasos.autoplay = false
		
	# BUSCAR AL JUGADOR POR NOMBRE EN LA ESCENA
	var jugador_encontrado = get_tree().current_scene.find_child("Player", true, false)
	if jugador_encontrado is CharacterBody3D:
		player = jugador_encontrado
		print("¡Jugador encontrado con éxito!")
	else:
		push_warning("Aviso: No se encontró ningún nodo llamado 'Player' en la escena.")

	# Configuración de distancias del agente
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 1.0
	
	# Esperamos un frame de físicas para que el mapa de navegación se inicialice
	await get_tree().physics_frame

func activar_estatua() -> void:
	esta_activa = true
	print("[ESTATUA]: Despertando... Iniciando búsqueda del jugador.")

# Esta función será llamada por el Player mediante el RayCast3D
func ser_mirada(estado: bool) -> void:
	jugador_mirando = estado
	
	# Control de audio de pasos cuando el jugador la congela con la mirada
	if audio_pasos and audio_pasos.playing:
		audio_pasos.stream_paused = estado

func _physics_process(delta: float) -> void:
	# Si por alguna razón el jugador no se vinculó al inicio, lo re-buscamos activamente
	if not player:
		var jugador_encontrado = get_tree().current_scene.find_child("Player", true, false)
		if jugador_encontrado is CharacterBody3D:
			player = jugador_encontrado

	if not esta_activa:
		velocity.x = 0.0
		velocity.z = 0.0
		if anim_player and anim_player.has_animation("Idle"):
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle")
		
		# Si no está activa, detenemos los pasos por completo
		if audio_pasos and audio_pasos.playing:
			audio_pasos.stop()
			
		move_and_slide()
		return

	# 1. Aplicar Gravedad
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	# =====================================================
	# 2. SI EL JUGADOR ESTÁ MIRANDO A LA ESTATUA (CONGELADA)
	# =====================================================
	if jugador_mirando:
		velocity.x = 0.0
		velocity.z = 0.0

		if anim_player and anim_player.has_animation("Idle"):
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle")

		move_and_slide()
		return

	# =====================================================
	# 3. MOVIMIENTO DE PERSECUCIÓN
	# =====================================================
	if player:
		# Actualizamos la posición destino del agente hacia el jugador
		nav_agent.target_position = player.global_transform.origin
		
		# Si ya llegó al rango del jugador
		if nav_agent.is_navigation_finished():
			velocity.x = 0.0
			velocity.z = 0.0

			if anim_player and anim_player.has_animation("Idle"):
				if anim_player.current_animation != "Idle":
					anim_player.play("Idle")
					
			if audio_pasos and audio_pasos.playing:
				audio_pasos.stop()
		else:
			# Obtenemos el siguiente punto del mapa de navegación
			var next_position: Vector3 = nav_agent.get_next_path_position()
			var current_position: Vector3 = global_transform.origin
			
			# Calculamos dirección
			var direction: Vector3 = next_position - current_position
			direction.y = 0
			
			if direction.length() > 0.05:
				direction = direction.normalized()
				
				# Movimiento
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
				
				# Reproducir bucle de pasos si está caminando y no está sonando ya
				if audio_pasos and not audio_pasos.playing:
					audio_pasos.play()
				
				# Orientar estatua
				var look_target = current_position + direction
				if current_position.distance_to(look_target) > 0.1:
					look_at(look_target, Vector3.UP)
				
				# Animación caminar formal
				if anim_player and anim_player.has_animation("Walk_Formal"):
					if anim_player.current_animation != "Walk_Formal":
						anim_player.play("Walk_Formal")
			else:
				velocity.x = 0.0
				velocity.z = 0.0
				if audio_pasos and audio_pasos.playing:
					audio_pasos.stop()
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if audio_pasos and audio_pasos.playing:
			audio_pasos.stop()

	# 4. Aplicar movimiento físico en el motor
	move_and_slide()

# =====================================================
# 4. DETECCIÓN A CORTA DISTANCIA (SEÑAL DEL AREA3D)
# =====================================================
func _on_area_3d_body_entered(body: Node3D) -> void:
	# Filtramos que sea el personaje utilizando minúscula o mayúscula según tu nodo raíz
	if (body.name == "Player" or body.name == "player") and not ya_hablo:
		if audio_voz and not audio_voz.playing:
			audio_voz.play()
			ya_hablo = true # Bloquea para que salte una única vez por evento
			print(">>> [ESTATUA SEÑAL]: ¡Jugador en radio corto! Reproduciendo audio_voz posicional. <<<")
