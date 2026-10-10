extends CharacterBody3D

# =========================================================
# MOVIMIENTO
# =========================================================

var correr = 22.0
var JUMP_VELOCITY = 5.2
var caminar = 16.6
var velocidad_actual = 10.6

# ========================================================= 
# STAMINA / SPRINT 
# ========================================================= 
@export var max_stamina: float = 100.0 
var current_stamina: float = 100.0 
@export var stamina_drain_rate: float = 25.0 
@export var stamina_recover_rate: float = 15.0
@onready var barra_stamina: ProgressBar = $CanvasLayer/BarraStamina
var cansado: bool = false

# =========================================================
# SANIDAD E INMERSIÓN
# =========================================================

@export var max_sanity: float = 100.0
var current_sanity: float = 100.0

@export var sanity_drain_rate: float = 15.0
@export var sanity_recover_rate: float = 5.0

# VARIABLES DE PELIGRO POR PROXIMIDAD (Mover aquí arriba):
@export var distancia_peligro_inmediato: float = 3.5
@export var multiplicador_drenaje_proximidad: float = 6.0

# REFERENCIAS DE UI Y AUDIO
@onready var filtro_oscuridad: ColorRect = $CanvasLayer/FiltroOscuridad
@onready var audio_respiracion: AudioStreamPlayer = get_node_or_null("AudioRespiracion")

# Estado de muerte para bloquear entradas
var esta_muerto: bool = false

# =========================================================
# REFERENCIAS DE COMPONENTES
# =========================================================

@onready var anim_player: AnimationPlayer = $Modelo/Body/AnimationPlayer
@onready var raycast_vision: RayCast3D = $Head/Camera3D/RayCast3D 

#=========================================================
# ESTATUA Y PAUSA
# =========================================================

var estatua_referencia: CharacterBody3D = null
var evento_activado: bool = false

# ALTERA ESTE VALOR: 
# Cámbialo de 3.0 a un tiempo más corto (por ejemplo, 1.0 o 0.5 segundos)
@export var tiempo_pausa_persecucion: float = 1.0 
var temporizador_pausa_estatua: float = 0.0
var esperando_para_reanudar: bool = false

# =========================================================
# INICIO
# =========================================================

func _ready() -> void:
	current_sanity = max_sanity
	current_stamina = max_stamina

	# Forzamos transparencia 0 en la visión al arrancar el nivel
	if filtro_oscuridad:
		filtro_oscuridad.color.a = 0.0

	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle")
		
	raycast_vision.target_position = Vector3(0, 0, -20)

	if barra_stamina:
		barra_stamina.max_value = max_stamina
		barra_stamina.value = current_stamina

	actualizar_efectos_sanidad()

# =========================================================
# FÍSICA
# =========================================================

func _physics_process(delta: float) -> void:
	if esta_muerto:
		return

	# 1. VISIÓN + SANIDAD
	comprobar_vision_y_sanidad(delta)

	# 2. GRAVEDAD Y SALTO
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("Saltar") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. DIRECCIÓN DE MOVIMIENTO
	var input_dir := Input.get_vector("Izquierda", "Derecha", "Adelante", "Atras")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 4. LÓGICA DE STAMINA Y CANSANCIO (20% MÍNIMO)
	if current_stamina <= 0.0:
		cansado = true

	var porcentaje_minimo: float = max_stamina * 0.2
	if cansado and current_stamina >= porcentaje_minimo:
		cansado = false

	if Input.is_action_pressed("correr") and not cansado and direction != Vector3.ZERO:
		velocidad_actual = correr
		current_stamina -= stamina_drain_rate * delta
	else:
		velocidad_actual = caminar
		current_stamina += stamina_recover_rate * delta
		
	current_stamina = clamp(current_stamina, 0.0, max_stamina)
	if barra_stamina:
		barra_stamina.value = current_stamina

	# 5. APLICAR VELOCIDAD Y ANIMACIÓN DE MOVIMIENTO
	if direction:
		velocity.x = direction.x * velocidad_actual
		velocity.z = direction.z * velocidad_actual

		if velocidad_actual == correr and anim_player and anim_player.has_animation("Sprint"):
			anim_player.play("Sprint")
		elif anim_player and anim_player.has_animation("Walk"):
			anim_player.play("Walk")
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)
		velocity.z = move_toward(velocity.z, 0, velocidad_actual)
		if anim_player and anim_player.has_animation("Idle"):
			anim_player.play("Idle")

	move_and_slide()

func comprobar_vision_y_sanidad(delta: float) -> void:
	var mirando_a_estatua := false
	var estatua_esta_cerca := false
	var lista_estatuas = get_tree().get_nodes_in_group("estatua")

	# -----------------------------------------------------
	# 1. DETECCIÓN DEL RAYCAST (INTERACCIONES)
	# -----------------------------------------------------
	if raycast_vision and raycast_vision.is_colliding():
		var objeto = raycast_vision.get_collider()
		
		if is_instance_valid(objeto):
			# Interacción con el Papel
			if objeto.has_method("interactuar"):
				print(">>> [RAYCAST] ¡Estás mirando al papel interactivo! <<<")
				
				if Input.is_action_just_pressed("interactuar"):
					print(">>> [TECLA PRESIONADA] Se interactuó con el papel <<<")
					objeto.interactuar()
					evento_activado = true 
					
					for estatua in lista_estatuas:
						if is_instance_valid(estatua) and estatua.has_method("activar_estatua"):
							estatua.activar_estatua()
							print(">>> ¡Estatua activada desde el Player! <<<")

			# Interacción con la Estatua (Mirarla para detenerla)
			elif objeto.has_method("ser_mirada"):
				# Si miramos a una estatua nueva o a la misma, cancelamos cualquier temporizador de espera
				if estatua_referencia != objeto:
					# Si ya teníamos una guardada antes, la liberamos primero de forma segura
					if is_instance_valid(estatua_referencia) and estatua_referencia.has_method("ser_mirada"):
						estatua_referencia.ser_mirada(false)
					estatua_referencia = objeto
				
				mirando_a_estatua = true
				esperando_para_reanudar = false
				temporizador_pausa_estatua = 0.0
				objeto.ser_mirada(true)

	# -----------------------------------------------------
	# CONTROLES DE REPROCHES Y TIEMPO DE ESPERA (RETRASO DESDE EL PLAYER)
	# -----------------------------------------------------
	if not mirando_a_estatua and is_instance_valid(estatua_referencia):
		if not esperando_para_reanudar:
			# El jugador dejó de mirar este fotograma, iniciamos la cuenta regresiva
			esperando_para_reanudar = true
			temporizador_pausa_estatua = tiempo_pausa_persecucion
		else:
			# Descontamos tiempo
			temporizador_pausa_estatua -= delta
			if temporizador_pausa_estatua <= 0.0:
				# Terminó el tiempo de gracia, ahora sí le avisamos a la estatua que se mueva
				if estatua_referencia.has_method("ser_mirada"):
					estatua_referencia.ser_mirada(false)
				estatua_referencia = null
				esperando_para_reanudar = false

	# -----------------------------------------------------
	# 2. CONTROL DEL EVENTO ACTIVO Y PROXIMIDAD
	# -----------------------------------------------------
	if not evento_activado:
		return

	# Evaluar si alguna estatua está demasiado cerca
	for nodo_estatua in lista_estatuas:
		if is_instance_valid(nodo_estatua):
			var pos_estatua_plana = nodo_estatua.global_position
			var pos_jugador_plana = global_position
			pos_estatua_plana.y = 0.0
			pos_jugador_plana.y = 0.0
			
			if pos_estatua_plana.distance_to(pos_jugador_plana) <= distancia_peligro_inmediato:
				estatua_esta_cerca = true
				break

	# Máquina de consecuencias de Sanidad
	if estatua_esta_cerca:
		current_sanity -= (sanity_drain_rate * multiplicador_drenaje_proximidad) * delta
		current_sanity = clamp(current_sanity, 0.0, max_sanity)
		actualizar_efectos_sanidad()
		
		if current_sanity <= 0 and not esta_muerto:
			morir()
			
	elif mirando_a_estatua:
		perder_sanidad(delta)
		
	else:
		recuperar_sanidad(delta)

# =========================================================
# GESTIÓN DE SANIDAD Y EFECTOS
# =========================================================

func perder_sanidad(delta: float) -> void:
	current_sanity -= sanity_drain_rate * delta
	current_sanity = clamp(current_sanity, 0.0, max_sanity)
	actualizar_efectos_sanidad()
	if current_sanity <= 0 and not esta_muerto:
		morir()

func recuperar_sanidad(delta: float) -> void:
	current_sanity += sanity_recover_rate * delta
	current_sanity = clamp(current_sanity, 0.0, max_sanity)
	actualizar_efectos_sanidad()

func actualizar_efectos_sanidad() -> void:
	if filtro_oscuridad:
		var perdida: float = 1.0 - (current_sanity / max_sanity)
		filtro_oscuridad.color.a = clamp(perdida * 0.85, 0.0, 0.85)

	if audio_respiracion:
		if current_sanity < max_sanity * 0.5:
			if not audio_respiracion.playing:
				audio_respiracion.play()
		else:
			if audio_respiracion.playing:
				audio_respiracion.stop()

func morir() -> void:
	esta_muerto = true
	velocity = Vector3.ZERO
	print("GAME OVER: Te has quedado sin cordura.")

	if anim_player and anim_player.has_animation("Death01"):
		print("Reproduciendo animación: Death01")
		anim_player.play("Death01")
	elif anim_player and anim_player.has_animation("Death01"):
		print("Reproduciendo animación: Death01")
		anim_player.play("Death01")

	# 2. Esperar 2 segundos (tiempo para ver caer al personaje) sin congelar el código
	print("Esperando que termine la secuencia visual...")
	await get_tree().create_timer(2.0).timeout

	# 3. Cambiar de escena forzadamente
	print("Cambiando a escena de Game Over...")
	var error_code = get_tree().change_scene_to_file("res://Gero_Menu/game_over.tscn")

	if error_code != OK:
		print("ERROR al cambiar de escena. Código de error: ", error_code)

func _on_button_pressed() -> void:
	pass
