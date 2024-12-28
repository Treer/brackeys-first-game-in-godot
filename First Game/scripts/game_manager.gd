extends Node

var score = 0

@onready var score_label = $ScoreLabel

func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."

func become_host():
	print("Become host pressed");
	%MultiplayerHud.hide()
	MultiplayerManager.become_host()
	
func join_as_player_2():
	print("Join as player 2");
	%MultiplayerHud.hide()
	MultiplayerManager.join_as_player_2()
