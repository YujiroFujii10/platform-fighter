extends Area2D


@export_enum("Left", "Right") var ledge_side := "Left"
@onready var label: Label = $Label
@onready var collision: CollisionShape2D = $CollisionShape2D


#called when the node enters the scene tree for the first time.
func _ready():
	if ledge_side == "Left":
		label.text = "Ledge_L"
	else:
		label.text = "Ledge_R"
