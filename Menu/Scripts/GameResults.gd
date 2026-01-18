extends Control

@onready var winner_label := $WinnerLabel
@onready var loser_label := $LoserLabel
@onready var continue_button := $Continue
@onready var winner_sprite := $WinnerPortrait/AnimatedSprite
@onready var winner_anim := $WinnerPortrait/AnimationPlayer
@onready var loser_sprite := $LoserPortrait/AnimatedSprite
@onready var loser_anim := $LoserPortrait/AnimationPlayer


func _ready():
	var winner_char: String
	var loser_char: String
	if Globals.winner_id == 1:
		winner_char = Globals.player1_character
		loser_char = Globals.player2_character
		winner_label.text = "P1 " + winner_char + " wins"
		loser_label.text = "P2 " + loser_char + " loses"
	else:
		winner_char = Globals.player2_character
		loser_char = Globals.player1_character
		winner_label.text = "P2 " + winner_char + " wins"
		loser_label.text = "P1 " + loser_char + " loses"
	setup_results(winner_char, loser_char)
	
	#temporary forced screen change
	await get_tree().create_timer(5.0).timeout
	Transition.change_scene("res://Menu/CharacterSelect.tscn")
	Globals.player1_character = ""
	Globals.player2_character = ""


func setup_results(winner_char: String, loser_char: String):
	# Load sprite frames
	winner_sprite.sprite_frames = load(
		"res://Characters/%s/%sFrames.tres" % [winner_char, winner_char]
	)
	loser_sprite.sprite_frames = load(
		"res://Characters/%s/%sFrames.tres" % [loser_char, loser_char]
	)
	# Play animations
	winner_sprite.play("Winner")
	loser_sprite.play("Loser")


func _on_continue_pressed():
	# Go back to character select with fade
	Transition.change_scene("res://Menu/CharacterSelect.tscn")
	Globals.player1_character = ""
	Globals.player2_character = ""
