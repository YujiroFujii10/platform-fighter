extends TextureRect

@export var player_number := 2
var dragging := false


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if not event.pressed:
			check_drop()  #check selection on release
	elif dragging:
		#follow mouse exactly
		global_position = get_global_mouse_position() - size / 2


func check_drop():
	var cursor_center: Vector2 = global_position + size / 2
	for button in get_tree().get_nodes_in_group("CharacterButton"):
		var rect: Rect2 = button.get_global_rect()
		if rect.has_point(cursor_center):
			#update selection
			if player_number == 1:
				Globals.player1_character = button.name
			elif player_number == 2:
				Globals.player2_character = button.name
			get_tree().current_scene.update_portraits()
			get_parent().update_start_button()
			#snap cursor to button center
			global_position = button.global_position + (button.size / 1) - (size / 2)
			return
	#if the cursor is released off any button, clear selection
	if player_number == 1:
		Globals.player1_character = ""
	elif player_number == 2:
		Globals.player2_character = ""
	get_tree().current_scene.update_portraits()
	get_parent().update_start_button()
