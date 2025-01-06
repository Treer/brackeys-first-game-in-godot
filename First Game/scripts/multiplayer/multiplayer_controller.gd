extends CharacterBody2D

# Multiplayer lag compensation with Netfox
# https://www.youtube.com/watch?v=GqHTNmRspjU

# WARNING - doesn't support rollback of physics, so might need to use a 
# StateSynchronizer + TickInterpolator on every physics object? (to learn)
# I think sync'ing properties with optional interpolation and optional simualtion 
# during rollback is the main scope of Netfox, so think in terms of sync'd properties.

# This scene uses RollbackSynchronizer, see the slime for an example of the
# StateSynchronizer. The TickInterpolator from netfox can support either.
# (MultiplayerSynchronizer (i.e. PlayerSynchronizer) is the Godot provided one that
# isn't network-tick aware)
#
# https://foxssake.github.io/netfox/latest/netfox/nodes/state-synchronizer/




const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var _respawning = false
var alive = true ## hack to allow ignoring erroneous collisions when respawning

@export var input: PlayerInput

# id 1 means the server
# this property is being synchronized with the PlayerSynchronizer,
# and gets called before the player is added to the scene (i.e. value will be available in _ready())
@export var player_id := 1:
	set(id):
		player_id = id
		# gives client authority to any scripts attached to the InputSynchronizer
		# (InputSynchronizer's script exposes player input, leaving this script server-authority, so cheats can't set velocity etc)
		input.set_multiplayer_authority(id)

@onready var animated_sprite = $AnimatedSprite2D
@onready var rollback_synchronizer = $RollbackSynchronizer

func _ready():
	# The camer that follows this player should only be active on the client for this player
	if multiplayer.get_unique_id() == player_id:
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false
		
	rollback_synchronizer.process_settings() # must be called after the multiplayer_authority is set

func _apply_animations(delta):
	var direction = input.input_direction
	
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

## apply movement from input in the _rollback_tick rather than the 
## physics process to apply it inside the network-tic loop and enable rollback
func _rollback_tick(delta, tick, is_fresh):
	if not _respawning:
		_apply_movement_from_input(delta)
	else:
		_respawning = false
		position = MultiplayerManager.respawn_point
		velocity = Vector2.ZERO
		$TickInterpolator.teleport() # prevent interpolating to this new position
		
		await get_tree().create_timer(0.5).timeout # pause before setting alive to true to give the un-disabling of $CollisionShape2D time to take effect
		alive = true

func _apply_movement_from_input(delta):
	
	# network-tick-loop hack needed before calling is_on_floor()
	_force_update_is_on_floor()
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	elif input.input_jump > 0:
		# Handle jump.
		velocity.y = JUMP_VELOCITY * input.input_jump
		
	# Get the input direction: -1, 0, 1
	var direction = input.input_direction
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# netfox docs detail how velocity needs to be multiuplied by physics_factor
	# before move_and_slide to scale it to the network-tick time, but if you want
	# then you can return it to the real value after the move_and_slide call.
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

## hack documented in netfox to force the is_on_floor() value to be
## updated, so we can read it in the network-tick
func _force_update_is_on_floor():
	# call move_and_slide() with no velocity
	var old_velocity = velocity
	velocity = Vector2.ZERO
	move_and_slide()
	velocity = old_velocity
	
	


func _process(delta):	
	if not multiplayer.is_server() || MultiplayerManager.host_mode_enabled:
		_apply_animations(delta)

func mark_dead():
	print("Mark player dead!")
	$CollisionShape2D.set_deferred("disabled", true)
	alive = false
	$RespawnTimer.start()

func _respawn():
	print("Respwaned!")
	$CollisionShape2D.set_deferred("disabled", false)
	_respawning = true
	#position = MultiplayerManager.respawn_point
	#velocity = Vector2.ZERO
