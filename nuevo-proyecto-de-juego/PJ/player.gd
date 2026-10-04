extends CharacterBody3D


# =========================================================
# MOVIMIENTO
# =========================================================

var correr = 8.0
var JUMP_VELOCITY = 4.5
var caminar = 40.6


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

		velocity.x = direction.x * caminar
		velocity.z = direction.z * caminar

		anim_player.play("Walk")

	else:

		velocity.x = move_toward(
			velocity.x,
			0,
			caminar
		)

		velocity.z = move_toward(
			velocity.z,
			0,
			caminar
		)

		anim_player.play("Idle")


	move_and_slide()


# =========================================================
# COMPROBAR VISIÓN DE LA ESTATUA + SANIDAD
# =========================================================

func comprobar_vision_y_sanidad(delta: float) -> void:

	var mirando_a_estatua := false


	# -----------------------------------------------------
	# ¿EL RAYCAST ESTÁ TOCANDO ALGO?
	# -----------------------------------------------------

	if raycast_vision.is_colliding():

		var objeto = raycast_vision.get_collider()


		# -------------------------------------------------
		# ¿ES LA ESTATUA?
		# -------------------------------------------------

		if objeto and objeto.has_method("ser_mirada"):

			# Guardamos referencia a la estatua
			estatua_referencia = objeto

			mirando_a_estatua = true

			# Avisamos a la estatua
			objeto.ser_mirada(true)

			# Perdemos sanidad
			perder_sanidad(delta)


	# -----------------------------------------------------
	# SI NO ESTAMOS MIRANDO A LA ESTATUA
	# -----------------------------------------------------

	if not mirando_a_estatua:

		if estatua_referencia and is_instance_valid(estatua_referencia):

			if estatua_referencia.has_method("ser_mirada"):

				estatua_referencia.ser_mirada(false)

		# Ya no estamos mirando a ninguna estatua
		estatua_referencia = null

		# Recuperamos sanidad
		recuperar_sanidad(delta)


# =========================================================
# PERDER SANIDAD
# =========================================================

func perder_sanidad(delta: float) -> void:

	current_sanity -= sanity_drain_rate * delta

	current_sanity = clamp(
		current_sanity,
		0.0,
		max_sanity
	)

	print("Sanidad actual: ", int(current_sanity))


	if current_sanity <= 0:

		game_over()


# =========================================================
# RECUPERAR SANIDAD
# =========================================================

func recuperar_sanidad(delta: float) -> void:

	if current_sanity < max_sanity:

		current_sanity += sanity_recover_rate * delta

		current_sanity = clamp(
			current_sanity,
			0.0,
			max_sanity
		)


# =========================================================
# GAME OVER
# =========================================================

func game_over() -> void:

	print("¡Has perdido la cordura por completo!")

	get_tree().change_scene_to_file(
		"res://game_over.tscn"
	)


# =========================================================
# BOTÓN
# =========================================================

func _on_button_pressed() -> void:

	pass
