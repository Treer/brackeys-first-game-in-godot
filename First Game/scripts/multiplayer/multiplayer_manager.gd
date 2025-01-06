extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

var multiplayer_scene = preload("res://scenes/multiplayer_player.tscn")

var _players_to_spawn_node

var host_mode_enabled = false
var multiplayer_mode_enabled = false

var respawn_point = Vector2(30, 20)

func become_host():
	print("Starting host!")
	
	_players_to_spawn_node = get_tree().current_scene.get_node("PlayersToSpawn")
	
	host_mode_enabled = true
	multiplayer_mode_enabled = true
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	# user the MultiplayerAPI provided by godot, and tell it that this instrance is a server
	multiplayer.multiplayer_peer = server_peer
	
	# connect a signal to our function to manage the connection of players
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	
	_remove_single_player()
	_add_player_to_game(1)

func single_player_mode():
	# doesn't work with netfox, possibly because we don't have a host and netfox
	# warns in its limitations section that:
	# > ownership is hard-coded in some cases. One such case is NetworkTime, which is always owned by the host peer and always takes the host peer's time as reference.
	
	print("Joined as offline MultiplayerPeer")
	_players_to_spawn_node = get_tree().current_scene.get_node("PlayersToSpawn")
	
	host_mode_enabled = true
	multiplayer_mode_enabled = true
	
	# OfflineMultiplayerPeer is already the default value
	# var offline_peer = OfflineMultiplayerPeer.new()
	# multiplayer.multiplayer_peer = offline_peer
	
	_remove_single_player()
	_add_player_to_game(multiplayer.multiplayer_peer.get_unique_id()) # get_unique_id() just returns 1

func join_as_player_2():
	print("Joined as player 2")
	
	multiplayer_mode_enabled = true
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer
	
	_remove_single_player()



func _add_player_to_game(id: int):
	print("Player %s joined the game!" % id)
	
	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	# The multplayerspawner monitors the PlayersToSpawn node for new childen, and spawns them to all connected clients when it sees them.
	_players_to_spawn_node.add_child(player_to_add, true)
	
func _del_player(id: int):
		print("Player %s left the game!" % id)
		if not _players_to_spawn_node.has_node(str(id)):
			return
		_players_to_spawn_node.get_node(str(id)).queue_free()
		
func _remove_single_player():
	print("Remove single player")
	# player is recreated on death, so get the reference dynamically
	var player_to_remove =  get_tree().current_scene.get_node("Player")
	player_to_remove.queue_free()
	
