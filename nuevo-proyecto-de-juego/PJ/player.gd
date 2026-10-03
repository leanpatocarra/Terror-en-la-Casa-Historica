extends CharacterBody3D


var correr = 8.0
var JUMP_VELOCITY = 4.5
var caminar = 40.0

@onready var anim_player: AnimationPlayer = $Modelo/Body/AnimationPlayer
@onready var raycast_vision: RayCast3D = $Head/Camera3D/RayCast3D

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")

var estatua_referencia: CharacterBody3D = null

func _ready() -> void:
	anim_player.play("Idle")
	raycast_vision.target_position = Vector3(0, 0, -20)

func _physics_process(delta: float) -> void:

	# =====================================================
	# VISIÓN DEL JUGADOR
	# =====================================================
	comprobar_vision()


	# =====================================================
	# GRAVEDAD
	# =====================================================
	if not is_on_floor():
		velocity += get_gravity() * delta


	# =====================================================
	# SALTO
	# =====================================================
	if Input.is_action_just_pressed("Saltar") and is_on_floor():
		velocity.y = JUMP_VELOCITY


	# =====================================================
	# MOVIMIENTO
	# =====================================================
	var input_dir := Input.get_vector("Izquierda", "Derecha", "Adelante", "Atras")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * caminar
		velocity.z = direction.z * caminar

		anim_player.play("Walk")

	else:
		velocity.x = move_toward(velocity.x, 0, caminar)
		velocity.z = move_toward(velocity.z, 0, caminar)

		anim_player.play("Idle")


	move_and_slide()



# =========================================================
# COMPROBAR SI ESTAMOS MIRANDO A LA ESTATUA
# =========================================================
func comprobar_vision() -> void:
	# Si el RayCast está colisionando con algo
	if raycast_vision.is_colliding():
		var objeto = raycast_vision.get_collider()

		# Verificamos si el objeto que el RayCast está tocando tiene el método de la estatua
		if objeto and objeto.has_method("ser_mirada"):
			objeto.ser_mirada(true)
			print("laestatuaestasiendomirada")
			return # Cortamos la ejecución aquí, está siendo mirada.

	# Si el RayCast no está tocando a la estatua, usamos nuestra referencia para avisarle que es libre de moverse
	if estatua_referencia and is_instance_valid(estatua_referencia):
		estatua_referencia.ser_mirada(false)
