extends Node2D

@export var player: CharacterBody2D


func _draw():
	if !player.shield_active:
		return

	var shape := player.shieldBoxShape.shape as CircleShape2D
	if shape == null:
		return

	draw_circle(Vector2.ZERO, shape.radius, player.shield_color)
	draw_arc(
		Vector2.ZERO,
		shape.radius,
		0,
		TAU,
		64,
		player.outline_color,
		player.outline_width
	)
