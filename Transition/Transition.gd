extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayer
var next_scene_path: String = ""


func _ready():
	# VERY IMPORTANT
	process_mode = Node.PROCESS_MODE_ALWAYS
	anim.process_mode = Node.PROCESS_MODE_ALWAYS
	anim.animation_finished.connect(_on_anim_finished)


func change_scene(path: String):
	next_scene_path = path
	visible = true
	anim.play("fade_out")


func _on_anim_finished(animation_name: String):
	if animation_name == "fade_out":
		# Unpause BEFORE changing scenes
		get_tree().paused = false
		get_tree().change_scene_to_file(next_scene_path)
		anim.play("fade_in")
	elif animation_name == "fade_in":
		# Hide overlay after fade-in completes
		visible = false
