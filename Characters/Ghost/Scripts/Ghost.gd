extends CharacterBody2D

#for disabling inputs during countdown
var input_enabled: bool = false
func set_input_enabled(active: bool) -> void:
	input_enabled = active

#global variable tracking frames
var frame = 0
var charge_frames = 0
var respawn_timer = 0


#shield
var shield_hp = 60
var shield_regen = 0.1
var shield_decay = 0.1
@export var shield_color := Color(0.4, 0.8, 1.0, 0.35)
@export var outline_color := Color(0.6, 0.9, 1.0, 0.9)
@export var outline_width := 2.0
var shield_active := false

#hurtbox shapes
var hurtbox_rect := RectangleShape2D.new()
var hurtbox_circle := CircleShape2D.new()

#player attributes
@export var id: int
@export var percentage = 0
@export var stocks = 3
@export var weight = 90
var invincible := false
signal out_of_stocks(player_id) 

#setup function for GameScene to initialize the player
func setup(_id: int, spawn_pos: Vector2) -> void:
	id = _id
	global_position = spawn_pos

#knockback
var hdecay
var vdecay
var knockback
var hitstun
var connected:bool

#grounded state variables
var dash_duration = 10
var jump_squat = 3

#landing state variables
var landing_frames = 0
var lag_frames = 0

#aerial state variables
var fastfall = false
var air_jump = 0
var air_dodge = 0
var air_dodge_input
@export var air_jump_max = 2
@export var air_dodge_max = 1

#ledge variables
var last_ledge: Area2D = null
var regrab = 30
var catch = false

#hitbox variables
@export var hitbox: PackedScene
@export var projectile: PackedScene
var selfState

#onready variables
@onready var GroundL = get_node('Raycasts/GroundL')
@onready var GroundR = get_node('Raycasts/GroundR')
@onready var SideL = get_node('Raycasts/SideL')
@onready var SideR = get_node('Raycasts/SideR')
@onready var CeilingL = get_node('Raycasts/CeilingL')
@onready var CeilingR = get_node('Raycasts/CeilingR')
@onready var LedgeGrabF = get_node('Raycasts/LedgeGrabF')
@onready var LedgeGrabB = get_node('Raycasts/LedgeGrabB')
@onready var gun_position = get_node("GunPosition")
@onready var states = $State
@onready var animation = $Sprite/AnimationPlayer
@onready var collisionBox: CollisionShape2D = $CollisionBox
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtboxShape: CollisionShape2D = $Hurtbox/HurtboxShape
@onready var shieldBox: Area2D = $ShieldBox
@onready var shieldBoxShape: CollisionShape2D = $ShieldBox/ShieldBoxShape

var RUNSPEED = 500
var DASHSPEED = 700
var WALKSPEED = 300
var JUMPFORCE = 600
var MAX_JUMPFORCE = 900
var DOUBLEJUMPFORCE = 800
var MAXAIRSPEED = 600
var AIR_ACCEL = 50
var FALLSPEED = 30
var FALLINGSPEED = 500
var MAXFALLSPEED = 800
var TRACTION = 40 * 2
var ROLL_DISTANCE = 700
var AIR_DODGE_SPEED = 600
var UP_B_LAUNCHSPEED = 1000
var SIDE_B_LAUNCHSPEED = 1300


#called when the node enters the scene tree for the first time.
func _ready():
	#collision box
	var shape := collisionBox.shape as RectangleShape2D
	shape.extents = Vector2(43, 40)
	collisionBox.shape = collisionBox.shape.duplicate()
	#hurtbox shapes
	hurtbox_rect.extents = Vector2(43, 40)
	hurtbox_circle.radius = 40
	hurtboxShape.shape = hurtbox_rect
	#shield box
	var shape3 := shieldBoxShape.shape as CircleShape2D
	shape3.radius = 60
	shieldBoxShape.disabled = true
	shieldBoxShape.shape = shieldBoxShape.shape.duplicate()


func _physics_process(delta):
	if not input_enabled:
		return
	$Frames.text = str(frame)
	selfState = states.text
	if shield_active:
		$ShieldVisual.queue_redraw()
	if invincible:
		$Sprite.modulate = Color(1, 1, 1, 0.5)
	else:
		$Sprite.modulate = Color.WHITE


func create_hitbox(width, height, damage, angle, base_kb, kb_scaling, duration, type, points, angle_flipper, hitlag = 1):
	var hitbox_instance = hitbox.instantiate()
	self.add_child(hitbox_instance)
	#rotates the points
	if direction() == 1:
		hitbox_instance.set_parameters(width, height, damage, angle, base_kb, kb_scaling, duration, type, points, angle_flipper, hitlag)
	else:
		var flip_x_points = Vector2(-points.x, points.y)
		hitbox_instance.set_parameters(width, height, damage, -angle + 180, base_kb, kb_scaling, duration, type, flip_x_points, angle_flipper, hitlag)
	return hitbox_instance


func create_projectile(dir_x, dir_y, point):
	#instance projectile
	var projectile_instance = projectile.instantiate()
	projectile_instance.player_list.append(self)
	get_parent().add_child(projectile_instance)
	#set position
	gun_position.set_position(point)
	if direction() == 1:
		projectile_instance.dir(dir_x,dir_y)
		projectile_instance.set_global_position(gun_position.get_global_position())
	elif direction() == -1:
		gun_position.position.x = -gun_position.position.x
		projectile_instance.dir(-(dir_x),dir_y)
		projectile_instance.set_global_position(gun_position.get_global_position())
		return projectile_instance


func update_frames(delta):
	frame += 1


func reset_frame():
	frame = 0


func turn(direction):
	var dir = 0
	if direction:
		dir = -1
	else:
		dir = 1
	$Sprite.set_flip_h(direction)
	# Flip ray directions based on facing dir
	LedgeGrabF.target_position = Vector2(dir * abs(LedgeGrabF.target_position.x), LedgeGrabF.target_position.y)
	LedgeGrabF.position.x = dir * abs(LedgeGrabF.position.x)
	LedgeGrabB.position.x = dir * abs(LedgeGrabB.position.x)
	LedgeGrabB.target_position = Vector2(-dir * abs(LedgeGrabF.target_position.x), LedgeGrabF.target_position.y)


func direction():
	if LedgeGrabF.target_position.x > 0:
		return 1
	else:
		return -1


func play_animation(animationName):
	animation.play(animationName)


func reset_jumps():
	air_jump = air_jump_max


func reset_air_dodge():
	air_dodge = air_dodge_max


func reset_ledge():
	last_ledge = null


func die():
	stocks -= 1
	percentage = 0
	velocity = Vector2.ZERO
	fastfall = false
	regrab = 30
	hitstun = 0
	global_position = Vector2(950, 500)
	if stocks <= 0:
		emit_signal("out_of_stocks", id)


#hurtbox and shielding
func reset_hurtbox():
	hurtboxShape.shape = hurtbox_rect
	hurtbox_rect.extents = Vector2(43, 40)
	hurtboxShape.position = Vector2.ZERO

func set_crouch_hurtbox():
	hurtbox_rect.extents = Vector2(43, 18)
	hurtboxShape.shape = hurtbox_rect
	hurtboxShape.position = Vector2(0, 20)

func shielding_hurtbox():
	hurtboxShape.shape = hurtbox_circle
	hurtboxShape.position = Vector2.ZERO

func reset_bubble_shield():
	var shape := shieldBoxShape.shape as CircleShape2D
	shield_hp = 60
	shape.radius = 60
	shieldBoxShape.disabled = true
	shieldBoxShape.position = Vector2.ZERO
	shield_active = false
	$ShieldVisual.queue_redraw()

func bubble_shield():
	var shape := shieldBoxShape.shape as CircleShape2D
	shape.radius = shield_hp
	shieldBoxShape.disabled = false
	shieldBoxShape.position = Vector2.ZERO
	shield_active = true
	$ShieldVisual.queue_redraw()

func disable_shield():
	var shape := shieldBoxShape.shape as CircleShape2D
	shape.radius = shield_hp
	shieldBoxShape.disabled = true
	shield_active = false
	$ShieldVisual.queue_redraw()

func disable_hurtbox():
	hurtboxShape.disabled = true
	invincible = true

func enable_hurtbox():
	hurtboxShape.disabled = false
	invincible = false


#attacks
func down_tilt():
	if frame == 5:
		create_hitbox(55, 20, 7, 75, 0.22, 0.3, 3, 'normal', Vector2(40, 23), 0, 1)
	if frame >= 10:
		return true

func up_tilt():
	if frame == 1:
		create_hitbox(40, 45, 4, 90, 0.2, 0.35, 3, 'normal', Vector2(33, -10), 0, 1)
	if frame == 7:
		create_hitbox(40, 30, 4, 90, 0.2, 0.35, 3, 'normal', Vector2(33, -40), 0, 1)
	if frame >= 11:
		return true

func forward_tilt():
	if frame == 4:
		create_hitbox(50, 20, 10, 20, 0.2, 0.24, 6, 'normal', Vector2(40, -5), 0, 1)
	if frame >= 10:
		return true

func jab():
	if frame == 1:
		create_hitbox(40, 20, 5, 45, 1, 0.02, 2, 'normal', Vector2(40, -5), 0, 1)
	if frame >= 5:
		return true

func dash_attack():
	if frame == 5:
		create_hitbox(70, 25, 7, 60, 0.2, 0.3, 6, 'normal', Vector2(0, -30), 0, 1)
	if frame == 11:
		create_hitbox(90, 25, 10, 60, 0.2, 0.3, 8, 'normal', Vector2(0, -30), 0, 1)
	if frame >= 25:
		return true

func down_air():
	if frame == 18:
		create_hitbox(80, 25, 8, -90, 1, 0.5, 18, 'normal', Vector2(0, 30), 0, 1)
	if frame >= 40:
		return true

func up_air():
	if frame == 10:
		create_hitbox(60, 45, 8, 90, 0.25, 0.3, 5, 'normal', Vector2(0, -20), 0, 1)
	if frame == 20:
		create_hitbox(70, 15, 8, 90, 0.25, 0.3, 6, 'normal', Vector2(0, -10), 0, 1)
	if frame >= 26:
		return true

func forward_air():
	if frame == 7:
		create_hitbox(50, 45, 14, 30, 0.35, 0.23, 12, 'normal', Vector2(35, -10), 0, 1)
	if frame == 20:
		create_hitbox(40, 30, 14, -90, 0.35, 0.23, 7, 'normal', Vector2(40, 25), 0, 1)
	if frame >= 35:
		return true

func back_air():
	if frame == 9:
		create_hitbox(50, 45, 11, 150, 0.3, 0.28, 6, 'normal', Vector2(-35, -10), 0, 1)
	if frame == 15:
		create_hitbox(40, 40, 11, 150, 0.3, 0.28, 5, 'normal', Vector2(-10, -40), 0, 1)
	if frame >= 25:
		return true

func neutral_air():
	if frame == 7:
		create_hitbox(50, 50, 12, 45, 0.3, 0.18, 15, 'normal', Vector2(0, 0), 0, 1)
	if frame >= 24:
		return true

func down_smash(charge_amount):
	var multiplier = (charge_amount * 0.01) + 1
	if frame == 15:
		create_hitbox(90, 20, 11 * multiplier, 10, 10, 0.2, 10, 'normal', Vector2(0, 10), 0, 1)
	if frame >= 40:
		return true

func up_smash(charge_amount):
	var multiplier = (charge_amount * 0.01) + 1
	if frame == 15:
		create_hitbox(60, 45, 15 * multiplier, 90, 0.35, 0.24, 6, 'normal', Vector2(0, -45), 0, 1)
	if frame == 21:
		create_hitbox(40, 40, 15 * multiplier, 90, 0.35, 0.24, 6, 'normal', Vector2(0, -40), 0, 1)
	if frame >= 48:
		return true

func forward_smash(charge_amount):
	var multiplier = (charge_amount * 0.01) + 1
	if frame == 16:
		create_hitbox(90, 40, 16 * multiplier, 30, 0.35, 0.28, 12, 'normal', Vector2(35, -10), 0, 1)
	if frame == 22:
		create_hitbox(90, 20, 16 * multiplier, 30, 0.35, 0.28, 7, 'normal', Vector2(40, 20), 0, 1)
	if frame >= 52:
		return true

func down_special():
	if frame == 16:
		create_hitbox(55, 55, 6, 45, 0.4, 0.4, 30, 'normal', Vector2(0, 0), 0, 1)
		disable_hurtbox()
	if frame >= 45:
		enable_hurtbox()
		return true

func up_special():
	if frame == 1:
		create_hitbox(50, 50, 14, 90, 0.3, 0.4, 30, 'normal', Vector2(0, -25), 0, 1)
	if frame >= 30:
		return true

func side_special(charge_amount):
	var multiplier = (charge_amount * 0.01) + 1
	if frame == 1:
		create_hitbox(50, 40, 7 * multiplier, 20, 0.4, 0.35, 25, 'normal', Vector2(35, 0), 0, 1)
	if frame >= 20:
		return true

func neutral_special():
	if frame == 4:
		create_projectile(1, 0, Vector2(50, 0))
	if frame >= 10:
		return true
