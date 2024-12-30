class_name PlayerInput extends Node

@onready var player = $".."

# Each player scene requires two synchronizers:
# * The PlayerSynchronizer syncs state from the server (is server-authoratative)
# * the InputSyncronizer syncs input from the client (is client-authoratative)
#
# Player scene is free to predict what it thinks the state will be, and update to server authoratative state
# as required.

# Client authority is given to this InputSynchronizer script (via MultiplayerPlayer.player_id setter),
# so it listens for input from its matching client (process and physics process are disabled on other
# client - see code in _ready()) and used RPCs to write to synchronized properties like do_jump 
# of the MultiplayerPlayer, while providing values like input_direction.
#
# The server-authority-by-default MultiplayerPlayer script reads these values and applies them to the 
# player scene.

## Properties to be synchronized by InputSynchronizer, and read by multiplayer_controller.gd
var input_direction = Vector2.ZERO
var input_jump = 0

func _ready() -> void:
	NetworkTime.before_tick_loop.connect(_gather)
	
	# avoid running these processes on all clients except the client this MultiplayerPlayer represents
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
	
	# give it an initial value
	input_direction = Input.get_axis("move_left", "move_right")
	
## the sync'd network-time-tic rquivalent of _physics_process
func _gather():
	if not is_multiplayer_authority():
		return
		
	input_direction = Input.get_axis("move_left", "move_right")
	
func _physics_process(delta: float) -> void:
	# give it the value from the player keyboard
	input_direction = Input.get_axis("move_left", "move_right")

func _process(delta):
	input_jump = Input.get_action_strength("jump")


		
