extends MultiplayerSynchronizer

@onready var player = $".."


# need to sort this out in your head
# this MultiplayerPlayer script is server authority (somehow maybe?) and listens for input from the client,
# and writes to the synchronized properties like do_jump of the MultiplayerPlayer,
# while providing values like input_direction

# read by multiplayer_controller.gd
var input_direction

func _ready() -> void:
	# avoid running these processes on all clients except the client this MultiplayerPlayer represents
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
	
	# give it an initial value
	input_direction = Input.get_axis("move_left", "move_right")
	
func _physics_process(delta: float) -> void:
	# give it the value from the player keyboard
	input_direction = Input.get_axis("move_left", "move_right")

func _process(delta):
	if Input.is_action_just_pressed("jump"):
		jump.rpc()
		
@rpc("call_local")
func jump():
	if multiplayer.is_server():
		player.do_jump = true
		
