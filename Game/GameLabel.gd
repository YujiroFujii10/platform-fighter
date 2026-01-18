extends Label


func _ready():
	# Wait one frame so size is calculated
	await get_tree().process_frame
	# Set pivot to center of label
	pivot_offset = size * 0.5
	# Start hidden
	visible = false
	scale = Vector2(0, 0)
