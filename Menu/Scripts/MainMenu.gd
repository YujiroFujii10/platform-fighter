extends Control


func _ready():
	$Menu/StartButton.pressed.connect(_on_start_pressed)
	$Menu/QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	Transition.change_scene("res://Menu/CharacterSelect.tscn")

func _on_quit_pressed():
	get_tree().quit()
