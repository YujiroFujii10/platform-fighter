extends Area2D

@export var GHOST_PROJECTILE_SPEED := 1500
@export var duration := 240
@export var damage := 4
@onready var parent = get_parent()

var frame := 0
var dir_x := 1
var dir_y := 0
var player_list := []


func _ready():
	player_list.append(parent)
	set_process(true)
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play()


func _process(delta):
	frame += 1
	if frame >= duration:
		queue_free()
		return
	var motion := Vector2(dir_x, dir_y).normalized() * GHOST_PROJECTILE_SPEED
	position += motion * delta
	#flip and rotate the sprite
	if $AnimatedSprite2D:
		$AnimatedSprite2D.flip_h = dir_x < 0
		rotation = Vector2(abs(dir_x), dir_y).angle()


func dir(directionx, directiony):
	dir_x = directionx
	dir_y = directiony


func _on_ghost_projectile_body_entered(body: Node2D) -> void:
	if body in player_list:
		return
	player_list.append(body)
	body.percentage += damage
	queue_free()
