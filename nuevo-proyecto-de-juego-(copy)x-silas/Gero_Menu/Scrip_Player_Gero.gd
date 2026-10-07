extends CharacterBody3D


var correr = 8.0
var JUMP_VELOCITY = 4.5
var caminar = 8.6


# Variables de Sanidad
@export var max_sanity: float = 100.0
var current_sanity: float = 100.0

@export var sanity_drain_rate: float = 15.0 # Cuánta sanidad pierde por segundo
@export var sanity_recover_rate: float = 5.0 # Cuánta recupera cuando no lo mira

# Referencias a No





	# Aquí puedes reiniciar la escena, pausar el juego o mostrar pantalla de Game Over
	# get_tree().reload_current_scene()


@onready var anim_player: AnimationPlayer = $Modelo/Body/AnimationPlayer
@onready var raycast_vision: RayCast3D = $Head/Camera3D/RayCast3D

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready() -> void:
	anim_player.play("Idle")
	raycast_vision.target_position = Vector3(0, 0, -20)
	current_sanity = max_sanity

func _physics_process(delta: float) -> void:

	# =====================================================
	# VISIÓN DEL JUGADOR
	# =====================================================
	comprobar_vision_y_sanidad(delta)


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

func comprobar_vision_y_sanidad(delta: float) -> void:
	var mirando_a_estatua: bool = false

	if raycast_vision.is_colliding():
		var objeto = raycast_vision.get_collider()
		
		# Verificamos si el objeto se llama "Estatua" (o si está en el grupo "Estatua")
		if objeto and (objeto.name == "Estatua_nueva" or objeto.is_in_group("Estatua_nueva")):
			mirando_a_estatua = true
			if objeto.has_method("ser_mirada"):
				objeto.ser_mirada(true)
			
			perder_sanidad(delta)



	# Si no estamos mirando a la estatua
	var estatua = get_tree().current_scene.find_child("Estatua", true, false)

	if estatua and estatua.has_method("ser_mirada"):
		estatua.ser_mirada(false)


	
	if current_sanity <= 0:
		game_over()
		get_tree().change_scene_to_file("res://game_over.tscn")



	# Puedes añadir aquí: get_tree().reload_current_scene() para reiniciar
func _process(delta):
	check_enemy_vision(delta)

func check_enemy_vision(delta):
	# 1. Verificar si el RayCast está colisionando con algo
	if raycast_vision.is_colliding():
		var collider = raycast_vision.get_collider()
		
		# 2. Verificar si el objeto colisionado está en el grupo "enemigo"
		if collider.is_in_group("Estatua"):
			perder_sanidad(delta)
			return # Salimos de la función para no recuperar sanidad
			
	# 3. Si no está mirando al enemigo, recupera sanidad poco a poco
	recuperar_sanidad(delta)

func perder_sanidad(delta):
	current_sanity -= sanity_drain_rate * delta
	current_sanity = clamp(current_sanity, 0.0, max_sanity)
	print("Sanidad actual: ", int(current_sanity))
	
	if current_sanity <= 0:
		game_over()

func recuperar_sanidad(delta):
	if current_sanity < max_sanity:
		current_sanity += sanity_recover_rate * delta
		current_sanity = clamp(current_sanity, 0.0, max_sanity)

func game_over():
	print("¡Has perdido la cordura por completo!")

func _on_button_pressed() -> void:
	pass # Replace with function body.
