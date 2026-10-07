extends CharacterBody3D

# =========================================================
# MOVIMIENTO
# =========================================================

var correr = 20.0
var JUMP_VELOCITY = 4.5
var caminar = 10.6
var velocidad_actual = 10.6  # <- CORREGIDO: Se declaró la variable que faltaba

# ========================================================= 
# STAMINA / SPRINT 
# ========================================================= 
@export var max_stamina: float = 100.0 
var current_stamina: float = 100.0 # Cantidad de stamina que gasta por segundo corriendo 
@export var stamina_drain_rate: float = 25.0 # Cantidad de stamina que recupera por segundo 
@export var stamina_recover_rate: float = 15.0
@onready var barra_stamina: ProgressBar = $CanvasLayer/BarraStamina
# Variable de control para evitar correr sin la estamina mínima (20%)
var cansado: bool = false

# =========================================================
# SANIDAD
# =========================================================

@export var max_sanity: float = 100.0
var current_sanity: float = 100.0

@export var sanity_drain_rate: float = 15.0
@export var sanity_recover_rate: float = 5.0

# =========================================================
# REFERENCIAS
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
	anim_player.play("Idle")
	raycast_vision.target_position = Vector3(0, 0, -20)
	current_sanity = max_sanity
	current_stamina = max_stamina
	if barra_stamina:
		barra_stamina.max_value = max_stamina
		barra_stamina.value = current_stamina

# =========================================================
# FÍSICA
# =========================================================

func _physics_process(delta: float) -> void:

	# -----------------------------------------------------
	# VISIÓN + SANIDAD
	# -----------------------------------------------------
	comprobar_vision_y_sanidad(delta)

	# -----------------------------------------------------
	# GRAVEDAD
	# -----------------------------------------------------
	if not is_on_floor():
		velocity += get_gravity() * delta

	# -----------------------------------------------------
	# SALTO
	# -----------------------------------------------------
	if Input.is_action_just_pressed("Saltar") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# -----------------------------------------------------
	# MOVIMIENTO
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

	if direction:
		# CORREGIDO: Ahora usa 'velocidad_actual' en lugar de 'caminar' fijo
		velocity.x = direction.x * velocidad_actual
		velocity.z = direction.z * velocidad_actual

		# Opcional: Cambiar animación según velocidad
		if velocidad_actual == correr:
			anim_player.play("Sprint") # Cambia por el nombre de tu animación de correr si existe
		else:
			anim_player.play("Walk")
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)
		velocity.z = move_toward(velocity.z, 0, velocidad_actual)
		anim_player.play("Idle")

	move_and_slide()

# -----------------------------------------------------
	# 4. LÓGICA DE STAMINA Y EXHAUSTIVIDAD (20% MÍNIMO)
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
	# 5. APLICAR VELOCIDAD Y ANIMACIÓN
	# -----------------------------------------------------
	if direction:
		velocity.x = direction.x * velocidad_actual
		velocity.z = direction.z * velocidad_actual

		if velocidad_actual == correr and anim_player.has_animation("Sprint"):
			anim_player.play("Sprint")
		else:
			anim_player.play("Walk")
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)
		velocity.z = move_toward(velocity.z, 0, velocidad_actual)
		anim_player.play("Idle")

	move_and_slide()

# =========================================================
# COMPROBAR VISIÓN DE LA ESTATUA + SANIDAD
# =========================================================

func comprobar_vision_y_sanidad(delta: float) -> void:
	var mirando_a_estatua := false

	if raycast_vision.is_colliding():
		var objeto = raycast_vision.get_collider()

		if objeto and objeto.has_method("ser_mirada"):
			estatua_referencia = objeto
			mirando_a_estatua = true
			objeto.ser_mirada(true)
			perder_sanidad(delta)

	if not mirando_a_estatua:
		if estatua_referencia and is_instance_valid(estatua_referencia):
			if estatua_referencia.has_method("ser_mirada"):
				estatua_referencia.ser_mirada(false)

		estatua_referencia = null
		recuperar_sanidad(delta)

# =========================================================
# PERDER SANIDAD
# =========================================================

func perder_sanidad(delta: float) -> void:
	current_sanity -= sanity_drain_rate * delta
	current_sanity = clamp(current_sanity, 0.0, max_sanity)
	print("Sanidad actual: ", int(current_sanity))

	if current_sanity <= 0:
		game_over()

# =========================================================
# RECUPERAR SANIDAD
# =========================================================

func recuperar_sanidad(delta: float) -> void:
	if current_sanity < max_sanity:
		current_sanity += sanity_recover_rate * delta
		current_sanity = clamp(current_sanity, 0.0, max_sanity)

# =========================================================
# GAME OVER
# =========================================================

func game_over() -> void:
	print("¡Has perdido la cordura por completo!")
	get_tree().change_scene_to_file("res://game_over.tscn")

# =========================================================
# BOTÓN
# =========================================================

func _on_button_pressed() -> void:
	pass
