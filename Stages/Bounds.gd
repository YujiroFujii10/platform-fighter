extends Area2D


func _ready():
	connect("body_exited", Callable(self, "_on_body_exited"))


func _on_body_exited(body):
	if body is CharacterBody2D:
		var statemachine = body.get_node("StateMachine")
		if statemachine:
			statemachine.set_state(statemachine.states['RESPAWN'])
		body.die()
