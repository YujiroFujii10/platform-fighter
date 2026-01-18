extends Control

@onready var selected_preview: TextureRect = $SelectedStagePreview


#map stage names → preview textures
var stage_textures := {
	"TestStage": preload("res://Stages/Stage1/Stage1Preview.png"),
	"Stage2": preload("res://Stages/Stage2/stageTemplate.png"),
	"Random": preload("res://Menu/Images/Random.png")
}


func _ready():
	selected_preview.visible = false  # Hidden by default
	for stage_button in $StageGrid.get_children():
		# Hover: show preview
		stage_button.mouse_entered.connect(Callable(self, "_on_stage_hovered").bind(stage_button))
		stage_button.mouse_exited.connect(Callable(self, "_on_stage_exited"))
		# Click: select immediately
		stage_button.pressed.connect(Callable(self, "_on_stage_pressed").bind(stage_button))
		$BackButton.pressed.connect(_on_back_pressed)


func _on_stage_hovered(button):
	update_preview(button.name)
	selected_preview.visible = true  # Show preview on hover


func _on_stage_exited():
	selected_preview.visible = false  # Hide preview as soon as mouse leaves


func _on_stage_pressed(button):
	Globals.selected_stage = button.name
	# Immediately go to game scene
	Transition.change_scene("res://Game/GameScene.tscn")

func _on_back_pressed():
	Globals.player1_character = ""
	Globals.player2_character = ""
	Globals.selected_stage = ""
	Transition.change_scene("res://Menu/CharacterSelect.tscn")


func update_preview(stage_name):
	if stage_textures.has(stage_name):
		selected_preview.texture = stage_textures[stage_name]
