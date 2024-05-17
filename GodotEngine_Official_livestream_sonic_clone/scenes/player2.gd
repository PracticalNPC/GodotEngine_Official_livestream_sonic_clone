extends CharacterBody2D

#velocity values
const SPEED = 420.0
const JUMP_VELOCITY = -400.0
const STOPPING_FRICTION_GROUND = 0.97
const STOPPING_FRICTION_AIR = 0.99
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#movement
var player_normal := Vector2.ZERO
var environment_velocity := Vector2.ZERO
var movement_velocity := Vector2.ZERO
var x_direction : int = 0

#states
enum STATES {GROUND, FALL, JUMP, HIT}
var state = STATES.GROUND
var prev_state = STATES.GROUND


#checks
var player_hit := false
var invulnerable := false


#nodes
@onready var down_raycast : RayCast2D = $Raycasts/DownRaycast
@onready var forward_raycast : RayCast2D = $Raycasts/ForwardRaycast
@onready var state_label = %StateLabel
@onready var environment_velocity_label = %EnvironmentVelocity
@onready var movement_velocity_label = %MovementVelocity
@onready var total_velocity_label = %TotalVelocity
@onready var KinematicNormalRaycast = $Raycasts/KinematicNormalRaycast
@onready var floor_normal_label = %FloorNormal
@onready var animation_player = $AnimationPlayer
@onready var CollectSound_node = $Sounds/collect
@onready var collectible_chain_timer = $Timers/CollectibleChainTimer
@onready var invulnerable_timer = $Timers/InvulnerableTimer
@onready var player_sprite = $PlayerSprite



#collectlbes
var collected_collectibles :=  0
var collectible_frequencies = [1.0, 32.0/27.0, 4/3.0, 3/2.0, 16/9.0 ]
var collectible_chain_counter := 0 


#debug
var print_now := false
var rng = RandomNumberGenerator.new()

func _physics_process(delta):
	match state:
		STATES.GROUND:
			if prev_state == STATES.FALL and print_now:
				print_now = false
			ground_movement(delta)
			if !is_on_floor():
				change_state(STATES.FALL)
				return
			if check_to_enter_fall():
				change_state(STATES.FALL)
				return
			#if player_hit:
				#change_state(STATES.HIT)
				#return
			if Input.is_action_just_pressed("ui_accept"):
				change_state(STATES.JUMP)
				return
		STATES.FALL:
			fall_movement(delta)
			if is_on_floor():
				if get_floor_normal().y < -.5:
					change_state(STATES.GROUND)
					return
		STATES.JUMP:
			fall_movement(delta)
			if is_on_floor():
				change_state(STATES.GROUND)
				return
	movement_velocity = movement_velocity.limit_length(350)
	velocity = environment_velocity + movement_velocity
	move_and_slide()
	update_labels()
	update_visual_raycasts()

func ground_movement(delta) -> void:
	player_normal = -get_floor_normal()
	x_direction = int(Input.get_axis("ui_left", "ui_right"))
	if x_direction != 0:
		if x_direction == -1:
			animation_player.play("MoveLeft")
		elif x_direction == 1:
			print("move right")
			animation_player.play("MoveRight")

		if is_down_normal_colliding():
			movement_velocity += down_raycast.target_position.rotated(-x_direction * PI/2) * SPEED * delta
		else:
			movement_velocity += player_normal.rotated(-x_direction * PI/2) * SPEED * delta
	else:

		animation_player.play("RESET")
		movement_velocity *= STOPPING_FRICTION_GROUND
	return 

func check_to_enter_fall() -> bool:
	if movement_velocity.length() < 175:
		if get_floor_normal().y > -0.5:#.1:#.5:
			return true
	return false

func fall_movement(delta) -> void:
	environment_velocity.y += gravity * delta
	x_direction = int(Input.get_axis("ui_left", "ui_right"))
	if x_direction != 0:
		movement_velocity.x += x_direction * SPEED * delta
	else:
		pass#movement_velocity.x = STOPPING_FRICTION_AIR
		

func update_labels()-> void:
	state_label.text = str("state: " , get_state_name(state))
	environment_velocity_label.text = str("environment_velocity" ,  environment_velocity,  " length: " , environment_velocity.length())
	movement_velocity_label.text = str("movement_velocity" ,  movement_velocity ,  " length: " , movement_velocity.length())
	total_velocity_label.text = str("total_velocity" ,  velocity , " length: " , velocity.length())
	floor_normal_label.text = str("floor normal: "  , get_floor_normal())
func change_state(new_state: int) -> void:
	exit_state(state,new_state)
	enter_state(state,new_state)

func get_state_name(input_state: int) -> String:
	match input_state:
		STATES.GROUND:
			return "GROUND"
		STATES.FALL:
			return "FALL"
		STATES.JUMP:
			return "JUMP"
		STATES.HIT:
			return "uwu"
	return "what?"

func exit_state(input_prev_state:int , new_state: int) -> void:
	match input_prev_state:
		STATES.FALL:
			environment_velocity = Vector2.ZERO
	prev_state = input_prev_state
	return

func update_visual_raycasts() -> void:
	forward_raycast.target_position = velocity
	KinematicNormalRaycast.target_position = player_normal * 11
func enter_state(prev_state:int , new_state: int) -> void:
	state = new_state
	print("entered state: " , get_state_name(state))
	match state:
		STATES.JUMP:
			jump()
		STATES.GROUND:
			movement_velocity.y = 0
		STATES.HIT:
			hit()
	return

func jump() -> void:
	#environment_velocity += JUMP_VELOCITY * -get_floor_normal() #* (movement_velocity.length() / 175)
	if movement_velocity.length() > 300:
		environment_velocity += JUMP_VELOCITY * -get_floor_normal() * (movement_velocity.length() / 300)
	else:
		environment_velocity += JUMP_VELOCITY * -get_floor_normal() 
	return


func is_down_normal_colliding() -> bool:
	down_raycast.target_position = ((forward_raycast.target_position.normalized() + -get_floor_normal()) /2).normalized() * 11
	#down_raycast.target_position = ((forward_raycast.target_position + -get_floor_normal()) /2)#.normalized() * 11
	down_raycast.force_raycast_update()
	if down_raycast.is_colliding():
		return true
	return  false
func forward_direction_colliding() -> bool:
	forward_raycast.force_raycast_update()
	if forward_raycast.is_colliding():
		return true
	return false

func hit() -> void:
	if collected_collectibles == 0:
		death()
		return
	animation_player.play("hit_animation")
	invulnerable = true
	invulnerable_timer.start()
	collected_collectibles = 0

func death() -> void:
	player_sprite.modulate = Color.RED
	return 

func _on_area_2d_area_entered(area: Area2D):
	var body : Node = area.get_parent()
	if body is CollectibleNode:
		collectible_chain_timer.start()
		body.play_sound(collectible_frequencies[collectible_chain_counter])
		collected_collectibles += 1
		if collectible_chain_counter < 4:
			collectible_chain_counter += 1
	if body is SpikeNode:
		player_hit = true 


func _on_collectible_chain_timer_timeout():
	collectible_chain_counter = 0


func _on_timer_timeout():
	invulnerable = false 
