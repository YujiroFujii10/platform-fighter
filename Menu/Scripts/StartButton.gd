extends Button 


func _pressed():
	if Globals.player1_character != "" and Globals.player2_character != "":
		Transition.change_scene("res://Menu/StageSelect.tscn")
		
