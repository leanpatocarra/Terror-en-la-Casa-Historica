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

# =========================================================
# ESTATUA
# =========================================================

var estatua_referencia: CharacterBody3D = null

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
	# Si el jugador está muerto, frena y bloquea todo input
	if esta_muerto:
		return

	# -----------------------------------------------------
	# 1. VISIÓN + SANIDAD
	# -----------------------------------------------------
	comprobar_vision_y_sanidad(delta)

	# -----------------------------------------------------
	# 2. GRAVEDAD Y SALTO
	# -----------------------------------------------------
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("Saltar") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# -----------------------------------------------------
	# 3. DIRECCIÓN DE MOVIMIENTO
	# -----------------------------------------------------
	var input_dir := Input.get_vector(
		"Izquierda",
		"Derecha",
		"Adelante",
		"Atras"
	)

	var direction := (
		transform.basis *
		Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	# -----------------------------------------------------
	# 4. LÓGICA DE STAMINA Y CANSANCIO (20% MÍNIMO)
	# -----------------------------------------------------
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

	# -----------------------------------------------------
	# 5. APLICAR VELOCIDAD Y ANIMACIÓN DE MOVIMIENTO
	# -----------------------------------------------------
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

# =========================================================
# COMPROBAR VISIÓN DE LA ESTATUA + SANIDAD (REVISADO)
# =========================================================

@export var distancia_peligro_inmediato: float = 3.5
@export var multiplicador_drenaje_proximidad: float = 6.0

func comprobar_vision_y_sanidad(delta: float) -> void:
	var mirando_a_estatua := false
	var estatua_esta_cerca := false

	# 1. PASO DE FRENTE: Verificar si el RayCast la cruza
	if raycast_vision.is_colliding():
		var objeto = raycast_vision.get_collider()
		if objeto and objeto.has_method("ser_mirada"):
			if estatua_referencia != objeto:
				estatua_referencia = objeto
			mirando_a_estatua = true
			objeto.ser_mirada(true)

	# 2. PASO DE POSICIÓN (SUELO): Buscar por grupo evaluando TODAS las estatuas del mapa
	var lista_estatuas = get_tree().get_nodes_in_group("estatua")
	
	for nodo_estatua in lista_estatuas:
		if is_instance_valid(nodo_estatua):
			var pos_estatua_plana = nodo_estatua.global_position
			var pos_jugador_plana = global_position
			pos_estatua_plana.y = 0.0
			pos_jugador_plana.y = 0.0
			
			# Si AL MENOS UNA de las estatuas está a menos de la distancia de peligro
			if pos_estatua_plana.distance_to(pos_jugador_plana) <= distancia_peligro_inmediato:
				estatua_esta_cerca = true
				break # Rompemos el bucle porque ya encontramos una cerca, no hace falta seguir buscando

	# 3. MÁQUINA DE CONSECUENCIAS (Drenaje físico directo)
	if estatua_esta_cerca:
		# Situación A: Está encima tuyo (Espalda o frente) -> Drenaje masivo e inmediato del filtro
		current_sanity -= (sanity_drain_rate * multiplicador_drenaje_proximidad) * delta
		current_sanity = clamp(current_sanity, 0.0, max_sanity)
		actualizar_efectos_sanidad()
		
		if current_sanity <= 0 and not esta_muerto:
			morir()
			
	elif mirando_a_estatua:
		# Situación B: Solo la mirás de lejos -> Drenaje estándar
		perder_sanity_normal(delta)
		
	else:
		# Situación C: No está cerca ni la mirás -> El filtro se aclara limpio
		if estatua_referencia and is_instance_valid(estatua_referencia):
			if estatua_referencia.has_method("ser_mirada"):
				estatua_referencia.ser_mirada(false)
		
		estatua_referencia = null
		recuperar_sanidad(delta)


# Función auxiliar para mantener tu ritmo original de daño al mirarla de lejos
func perder_sanity_normal(delta: float) -> void:
	current_sanity -= sanity_drain_rate * delta
	current_sanity = clamp(current_sanity, 0.0, max_sanity)
	actualizar_efectos_sanidad()
	if current_sanity <= 0 and not esta_muerto:
		morir()


# =========================================================
# ACTUALIZAR SANIDAD (EFECTOS VISUALES Y AUDITIVOS)
# =========================================================

func actualizar_efectos_sanidad() -> void:
	# Porcentaje de cordura perdida (0.0 = sanidad llena, 1.0 = sanidad en cero)
	var perdida: float = 1.0 - (current_sanity / max_sanity)

	# 1. Filtro de oscuridad: aumenta la opacidad (Alpha) del ColorRect
	if filtro_oscuridad:
		filtro_oscuridad.color.a = perdida

	# 2. Control de audio de respiración
	if audio_respiracion:
		if perdida > 0.1:
			if not audio_respiracion.playing:
				audio_respiracion.play()
			audio_respiracion.volume_db = lerp(-20.0, 5.0, perdida)
		else:
			if audio_respiracion.playing:
				audio_respiracion.stop()

# =========================================================
# PERDER SANIDAD
# =========================================================

func perder_sanidad(delta: float) -> void:
	current_sanity -= sanity_drain_rate * delta
	current_sanity = clamp(current_sanity, 0.0, max_sanity)
	actualizar_efectos_sanidad()

	if current_sanity <= 0 and not esta_muerto:
		morir()

# =========================================================
# RECUPERAR SANIDAD
# =========================================================

func recuperar_sanidad(delta: float) -> void:
	if current_sanity < max_sanity:
		current_sanity += sanity_recover_rate * delta
		current_sanity = clamp(current_sanity, 0.0, max_sanity)
		actualizar_efectos_sanidad()

# =========================================================
# LÓGICA DE MUERTE Y GAME OVER
# =========================================================

func morir() -> void:
	if esta_muerto:
		return
		
	esta_muerto = true
	velocity = Vector3.ZERO
	print("--- INICIANDO SECUENCIA DE MUERTE ---")

	# 1. Intentar reproducir la animación
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
