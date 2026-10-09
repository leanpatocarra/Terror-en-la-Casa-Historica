extends CharacterBody3D

# --- CONFIGURACIÓN DE MOVIMIENTO ---
@export var SPEED: float = 20.0
const GRAVITY: float = 9.8

# --- CONFIGURACIÓN DEL RETRASO (DELAY) ---
@export var tiempo_retraso: float = 2.0 
var esperando_para_moverse: bool = false
var delay_timer: SceneTreeTimer = null

# --- REFERENCIAS A NODOS INTERNOS CORREGIDAS ---
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# --- REFERENCIA AL JUGADOR ---
var player: CharacterBody3D = null

# --- ESTADO DE VISIÓN ---
var jugador_mirando: bool = false


func _ready() -> void:
	if anim_player:
		print("AnimationPlayer encontrado: ", anim_player.get_path())
		print("Animaciones disponibles: ", anim_player.get_animation_list())
	else:
		push_error("No se encontró el AnimationPlayer de la nueva estatua")
		
	var jugador_encontrado = get_tree().current_scene.find_child("Player", true, false)
	if jugador_encontrado is CharacterBody3D:
		player = jugador_encontrado
		print("¡Jugador encontrado con éxito!")
	else:
		push_warning("Aviso: No se encontró ningún nodo llamado 'Player' en la escena.")

	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 1.0
	
	await get_tree().physics_frame


func ser_mirada(estado: bool) -> void:
	if jugador_mirando == true and estado == false:
		activar_retraso_movimiento()
		
	if estado == true:
		esperando_para_moverse = false
		delay_timer = null

	jugador_mirando = estado


func activar_retraso_movimiento() -> void:
	esperando_para_moverse = true
	delay_timer = get_tree().create_timer(tiempo_retraso)
	await delay_timer.timeout
	if not jugador_mirando:
		esperando_para_moverse = false


func _physics_process(delta: float) -> void:
	# Si por alguna razón el jugador no se vinculó al inicio, lo re-buscamos activamente
	if not player:
		var jugador_encontrado = get_tree().current_scene.find_child("Player", true, false)
		if jugador_encontrado is CharacterBody3D:
			player = jugador_encontrado

	# COMUNICACIÓN DIRECTA CON EL PLAYER (Siempre activa al inicio del frame)
	if player and player.has_method("registrar_posicion_estatua"):
		player.registrar_posicion_estatua(global_position)

	# 1. Aplicar Gravedad
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	# =====================================================
	# 2. SI EL JUGADOR LA MIRA *O* LA ESTATUA ESTÁ EN COOLDOWN/RETRASO
	# =====================================================
	if jugador_mirando or esperando_para_moverse:
		velocity.x = 0.0
		velocity.z = 0.0

		if anim_player and anim_player.has_animation("Idle"):
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle")

		move_and_slide()
		return # Cortamos ejecución de movimiento hacia el jugador de forma segura

	# =====================================================
	# 3. MOVIMIENTO DE PERSECUCIÓN
	# =====================================================
	if player:
		nav_agent.target_position = player.global_transform.origin
		
		if nav_agent.is_navigation_finished():
			velocity.x = 0.0
			velocity.z = 0.0

			if anim_player and anim_player.has_animation("Idle"):
				if anim_player.current_animation != "Idle":
					anim_player.play("Idle")
		else:
			var next_position: Vector3 = nav_agent.get_next_path_position()
			var current_position: Vector3 = global_transform.origin
			
			var direction: Vector3 = next_position - current_position
			direction.y = 0
			
			if direction.length() > 0.05:
				direction = direction.normalized()
				
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
				
				var look_target = current_position + direction
				if current_position.distance_to(look_target) > 0.1:
					look_at(look_target, Vector3.UP)
				
				if anim_player and anim_player.has_animation("Walk_Formal"):
					if anim_player.current_animation != "Walk_Formal":
						anim_player.play("Walk_Formal")
			else:
				velocity.x = 0.0
				velocity.z = 0.0
				if anim_player and anim_player.has_animation("Idle"):
					if anim_player.current_animation != "Idle":
						anim_player.play("Idle")
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
