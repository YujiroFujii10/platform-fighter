extends Label

signal countdown_finished

# Countdown sequence
var countdown_numbers := ["3", "2", "1", "GO!"]
@onready var anim := $AnimationPlayer


func _ready():
	visible = false
	scale = Vector2.ZERO
	# Ensure pivot is centered for scaling
	await get_tree().process_frame
	pivot_offset = size * 0.5


func play_countdown():
	# Start from first number
	start_countdown(0)


func start_countdown(index: int) -> void:
	if index >= countdown_numbers.size():
		# Countdown finished
		emit_signal("countdown_finished")
		return
	text = countdown_numbers[index]
	visible = true
	scale = Vector2.ZERO
	anim.play("CountPulse")  # scale/fade animation
	# Wait for animation duration, then show next number
	var duration = anim.current_animation_length*3
	await get_tree().create_timer(duration).timeout
	start_countdown(index + 1)
