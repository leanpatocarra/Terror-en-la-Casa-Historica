extends CharacterBody3D


var correr = 8.0
var JUMP_VELOCITY = 4.5
var caminar = 40.0

@onready var anim_player: AnimationPlayer = $Modelo/Body/AnimationPlayer
@onready var raycast_vision: RayCast3D = $Head/Camera3D/RayCast3D

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")


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

	if raycast_vision.is_colliding():

		var objeto = raycast_vision.get_collider()

		if objeto is CharacterBody3D and objeto.name == "Estatua":

			objeto.ser_mirada(true)
			return


	# Si no estamos mirando a la estatua
	var estatua = get_tree().current_scene.find_child("Estatua", true, false)

	if estatua and estatua.has_method("ser_mirada"):
		estatua.ser_mirada(false)
