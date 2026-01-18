extends Button

@export var hover_scale := 1.1
@export var press_scale := 0.95
@export var anim_speed := 12.0

var target_scale := Vector2.ONE
var target_modulate := Color.WHITE


func _ready():
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	button_down.connect(_on_press)
	button_up.connect(_on_release)

func _on_hover():
	target_scale = Vector2.ONE * hover_scale
	target_modulate = Color(1.1, 1.1, 1.1)

func _on_unhover():
	target_scale = Vector2.ONE
	target_modulate = Color.WHITE

func _on_press():
	target_scale = Vector2.ONE * press_scale
	target_modulate = Color(0.8, 0.8, 0.8)

func _on_release():
	target_scale = Vector2.ONE * hover_scale
	target_modulate = Color(1.1, 1.1, 1.1)

func _process(delta):
	scale = scale.lerp(target_scale, anim_speed * delta)
	modulate = modulate.lerp(target_modulate, anim_speed * delta)
