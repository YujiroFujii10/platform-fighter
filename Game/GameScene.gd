extends Node2D

@onready var stage_root: Node2D = $StageRoot
@onready var player_root: Node2D = $PlayerRoot
@onready var spawns := $PlayerSpawns
@onready var hud := $HUD
@onready var camera := $Camera2D
@onready var game_label := $GameEndUI/GameLabel


func _ready():
	load_stage()
	var players = spawn_players()
	hud.set_players(players[0], players[1])
	camera_setup(players)
	# Disable player input before countdown
	set_players_active(false)
	# Connect countdown finished signal
	$GameStartUI/CenterContainer/CountdownLabel.countdown_finished.connect(_on_countdown_finished)
	# Start countdown
	$GameStartUI/CenterContainer/CountdownLabel.play_countdown()


# -------------------
# LOAD STAGE
# -------------------
func load_stage():
	var stages := {
		"TestStage": preload("res://Stages/Stage1/TestStage.tscn"),
		"Stage2": preload("res://Stages/Stage2/Stage2.tscn"),
	}
	var stage_scene: PackedScene
	if Globals.selected_stage == "Random":
		stage_scene = stages.values().pick_random()
	else:
		stage_scene = stages[Globals.selected_stage]
	var stage = stage_scene.instantiate()
	stage_root.add_child(stage)


# -------------------
# SPAWN PLAYERS
# -------------------
func spawn_players():
	var players = []
	# --- Player 1 ---
	if Globals.player1_character == "Random":
		Globals.player1_character = random_character()
	var p1_scene = load("res://Characters/%s/%s.tscn" % [Globals.player1_character, Globals.player1_character])
	var p1 = p1_scene.instantiate()
	p1.setup(1, spawns.get_node("P1").global_position)
	player_root.add_child(p1)
	players.append(p1)
	p1.connect("out_of_stocks", Callable(self, "_on_player_out_of_stocks"))
	# --- Player 2 ---
	if Globals.player2_character == "Random":
		Globals.player2_character = random_character()
	var p2_scene = load("res://Characters/%s/%s.tscn" % [Globals.player2_character, Globals.player2_character])
	var p2 = p2_scene.instantiate()
	p2.setup(2, spawns.get_node("P2").global_position)
	player_root.add_child(p2)
	players.append(p2)
	p2.connect("out_of_stocks", Callable(self, "_on_player_out_of_stocks"))
	return players


func random_character():
	var characters = ["Ghost"]
	return characters.pick_random()


func _on_player_out_of_stocks(player_id: int):
	# Decide winner
	var winner_id: int
	if player_id == 1:
		winner_id = 2
	else:
		winner_id = 1
	Globals.winner_id = winner_id
	end_game()


func end_game():
	get_tree().paused = true
	var game_label = $GameEndUI/CenterContainer/GameLabel
	game_label.visible = true
	game_label.get_node("AnimationPlayer").play("GameExpand")
	await get_tree().create_timer(1, true).timeout
	Transition.change_scene("res://Menu/GameResults.tscn")


func set_players_active(active: bool) -> void:
	for player in player_root.get_children():
		# Assuming each player has a 'set_input_enabled(bool)' method
		if player.has_method("set_input_enabled"):
			player.set_input_enabled(active)


func _on_countdown_finished():
	# Hide countdown
	$GameStartUI.visible = false
	# Enable players and start the game
	set_players_active(true)


# -------------------
# CAMERA SETUP (TEMP)
# -------------------
func camera_setup(players):
	pass
