extends AnimatableBody2D

# disabled client-side animation of platforms


@export var animation_player_optional: AnimationPlayer

func _on_player_connected(id):
	if not multiplayer.is_server():
		animation_player_optional.stop()
		animation_player_optional.active = false

func _ready():
	if animation_player_optional:
		multiplayer.peer_connected.connect(_on_player_connected)
