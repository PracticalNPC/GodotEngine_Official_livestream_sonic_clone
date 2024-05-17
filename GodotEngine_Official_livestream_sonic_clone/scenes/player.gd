extends CharacterBody2D


const SPEED = 1500.0
const JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var down_normal := Vector2(0,1)
var forward_normal := Vector2(0,1)
var forward_direction := Vector2.ZERO
var movement_velocity := Vector2.ZERO
var environment_velocity := Vector2.ZERO


#node
@onready var down_raycast : RayCast2D = $Raycasts/DownNormal
@onready var forward_raycast : RayCast2D= $Raycasts/CheckForward

func _ready():
	Engine.time_scale = .25
	

func _physics_process(delta):
	# Add the gravity.
	#player_input()
	print("is_on floor: " , is_on_floor())
	appy_gravity(delta)
	movement(delta)
	move_and_slide()

func appy_gravity(delta) -> void:
	if not is_on_floor():
		environment_velocity.y += gravity * delta 
	else:
		var direction = int(Input.get_axis("ui_left", "ui_right"))
		if direction != 0.0:
			environment_velocity += -get_floor_normal() * delta
		else:
			environment_velocity.y += gravity * delta
	environment_velocity = environment_velocity.normalized() * 175
	print("environment_velocity" , environment_velocity)

func movement(delta) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		#movement_velocity.y = JUMP_VELOCITY
		if Engine.time_scale == .25:
			print("set to 1")
			Engine.time_scale = 1
		else:
			print("set to .5")
			Engine.time_scale = .25
	var direction = int(Input.get_axis("ui_left", "ui_right"))
	if direction:
		var player_normal = -get_floor_normal()
		print("player_normal: " , player_normal)
		if player_normal != Vector2.ZERO:
			forward_raycast.target_position = movement_velocity.normalized() * 32
			if is_down_normal_colliding():
				movement_velocity += down_raycast.target_position.rotated(-direction * PI/2) * SPEED * delta
			else:
				movement_velocity += player_normal.rotated(-direction * PI/2) * SPEED * delta
		else:
			movement_velocity.x += direction * SPEED * delta
			movement_velocity.y *= .99
	else:
		movement_velocity *= .99 #= Vector2.ZERO

	velocity = environment_velocity + movement_velocity 

func is_down_normal_colliding() -> bool:
	down_raycast.target_position = ((forward_raycast.target_position.normalized() + -get_floor_normal()) /2).normalized() * 11
	down_raycast.force_raycast_update()
	if down_raycast.is_colliding():
		return true
	return  false
func forward_direction_colliding() -> bool:
	forward_raycast.force_raycast_update()
	if forward_raycast.is_colliding():
		return true
	return false
