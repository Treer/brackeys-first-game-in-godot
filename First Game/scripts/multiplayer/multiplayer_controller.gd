extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# these properties are being synchronized with the InputSynchronizer
var direction = 1
var do_jump = false
var _is_on_floor = true
var alive = true # hack to allow ignoring erroneous collisions when respawning

# id 1 means the server
# this property is being synchronized with the PlayerSynchronizer
@export var player_id := 1:
	set(id):
		player_id = id
		# gives client authority to any scripts attached to the InputSynchronizer
		# (InputSynchronizer's script exposes player input, leaving this script server-authority, so cheats can't set velocity etc)
		%InputSynchronizer.set_multiplayer_authority(id)

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# The camer that follows this player should only be active on the client for this player
	if multiplayer.get_unique_id() == player_id:
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false

func _apply_animations(delta):
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if _is_on_floor:
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
		
func _apply_movement_from_input(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if do_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY
		do_jump = false

	# Get the input direction: -1, 0, 1
	direction = %InputSynchronizer.input_direction
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _physics_process(delta):
	if multiplayer.is_server():
		if not alive && is_on_floor():
			# setting alive here to give the physics process a chance to re-establish 
			# the collision shape, to avoid a false negative collision bug (hack)
			_set_alive();
		
		_is_on_floor = is_on_floor()
		_apply_movement_from_input(delta)
		
	if not multiplayer.is_server() || MultiplayerManager.host_mode_enabled:
		_apply_animations(delta)

func mark_dead():
	print("Mark player dead!")
	alive = false
	$CollisionShape2D.set_deferred("disabled", true)
	$RespawnTimer.start()

func _respawn():
	print("Respwaned!")
	position = MultiplayerManager.respawn_point
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", false)
	
func _set_alive():
	print( "alive again!")
	alive = true
	Engine.time_scale = 1.0
