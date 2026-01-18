extends Control

@onready var start_container: Control = $StartContainer
@onready var p1_portrait: TextureRect = $BottomUI/Player1Portrait
@onready var p2_portrait: TextureRect = $BottomUI/Player2Portrait


#map character ID → portrait texture
var character_portraits := {
	"Ghost": preload("res://Characters/Ghost/Sprites/GhostHitStun.png"),
	"Random": preload("res://Menu/Images/Random.png"),
}


func _ready():
	update_portraits()
	update_start_button()
	$BackButton.pressed.connect(_on_back_pressed)


func _on_back_pressed():
	start_container.visible = false
	Globals.player1_character = ""
	Globals.player2_character = ""
	Transition.change_scene("res://Menu/MainMenu.tscn")


func update_start_button():
	#require both players (change logic if you want 1-player support)
	if Globals.player1_character != "" and Globals.player2_character != "":
		start_container.visible = true
	else:
		start_container.visible = false


func update_portraits():
	#player 1
	if Globals.player1_character != "":
		p1_portrait.texture = character_portraits.get(Globals.player1_character)
		p1_portrait.visible = true
	else:
		p1_portrait.visible = false
	#player 2
	if Globals.player2_character != "":
		p2_portrait.texture = character_portraits.get(Globals.player2_character)
		p2_portrait.visible = true
	else:
		p2_portrait.visible = false
