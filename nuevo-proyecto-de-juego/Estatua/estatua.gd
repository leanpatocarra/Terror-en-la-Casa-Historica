extends CharacterBody3D

# --- CONFIGURACIÓN DE MOVIMIENTO ---
@export var SPEED: float = 3.0
const GRAVITY: float = 9.8

# --- REFERENCIAS A NODOS INTERNOS ---
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $Modelo/Body/AnimationPlayer

# --- REFERENCIA AL JUGADOR ---
var player: CharacterBody3D = null

# --- ESTADO DE VISIÓN ---
var jugador_mirando: bool = false


func _ready() -> void:
	# BUSCAR AL JUGADOR POR NOMBRE EN LA ESCENA
	var jugador_encontrado = get_tree().current_scene.find_child("Player", true, false)
	if jugador_encontrado is CharacterBody3D:
		player = jugador_encontrado
		print("¡Jugador encontrado con éxito!")
	else:
		push_warning("Aviso: No se encontró ningún nodo llamado 'Player' en la escena.")
	
		
	# Configuración de distancias del agente
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 5.0
	
	# Esperamos un frame de físicas para que el mapa de navegación se inicialice
	await get_tree().physics_frame
	print("Mapa de navegación válido: ", nav_agent.get_navigation_map().is_valid())

# Esta función será llamada por el Player
func ser_mirada(estado: bool) -> void:
	jugador_mirando = estado


func _physics_process(delta: float) -> void:

	# Si por alguna razón el jugador no se vinculó al inicio, lo re-buscamos activamente
	if not player:
		var jugador_encontrado = get_tree().current_scene.find_child("Player", true, false)
		if jugador_encontrado is CharacterBody3D:
			player = jugador_encontrado

	# 1. Aplicar Gravedad
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	# =====================================================
	# 2. SI EL JUGADOR ESTÁ MIRANDO A LA ESTATUA
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
		print("OBJETIVO ALCANZABLE: ", nav_agent.is_target_reachable())
		print(
	"ESTATUA: ", global_position,
	" | PLAYER: ", player.global_position,
	" | SIGUIENTE: ", nav_agent.get_next_path_position(),
	" | TERMINADO: ", nav_agent.is_navigation_finished()
)
		print("CANTIDAD DE PUNTOS: ", nav_agent.get_current_navigation_path().size())
		# Si ya llegó al rango del jugador
		if nav_agent.is_navigation_finished():
			velocity.x = 0.0
			velocity.z = 0.0

			if anim_player and anim_player.has_animation("Idle"):
				if anim_player.current_animation != "Idle":
					anim_player.play("Idle")

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
				
				print("ESTATUA MOVIÉNDOSE - VELOCIDAD: ", velocity)
				# Orientar estatua
				var look_target = current_position + direction
				
				if current_position.distance_to(look_target) > 0.1:
					look_at(look_target, Vector3.UP)
				
				# Animación caminar
				if anim_player and anim_player.has_animation("Walk"):
					if anim_player.current_animation != "Walk":
						anim_player.play("Walk")

			else:
				velocity.x = 0.0
				velocity.z = 0.0

	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# 4. Aplicar movimiento
	move_and_slide()
