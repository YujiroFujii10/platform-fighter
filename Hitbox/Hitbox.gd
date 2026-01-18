extends Area2D


@onready var parent = get_parent()
@export var width = 300
@export var height = 400
@export var damage = 50
@export var angle = 90
@export var base_kb = 100
@export var kb_scaling = 2
@export var duration = 1500
@export var hitlag_modifier = 1
@export var type = 'normal'
@export var angle_flipper = 0
@onready var hitbox = get_node("HitboxShape")
@onready var parentState = get_parent().selfState
var knockback_value
var hitbox_frames = 0.0
var player_list = []


#function to set up a hitbox
func set_parameters(w, h, d, a, b_kb, kb_s, dur, t, p, af, hit, parent = get_parent()):
	self.position = Vector2(0,0)
	player_list.append(parent)
	player_list.append(self)
	width = w
	height = h
	damage = d
	angle = a
	base_kb = b_kb
	kb_scaling = kb_s
	duration = dur
	type = t
	self.position = p
	hitlag_modifier = hit
	angle_flipper = af
	update_extents()
	connect("area_entered", Callable(self, "Hitbox_Collide"))
	set_physics_process(true)


func Hitbox_Collide(area: Area2D):
	var body := area.get_parent() as CharacterBody2D
	if body == null:
		return
	#shield was hit (can potentially implement block stun here)
	if area.name == "ShieldBox":
		return
	elif (body not in player_list) and shield_ignore(body):
		player_list.append(body)
		weight = body.weight
		body.percentage += damage
		knockback_value = knockback(body.percentage, damage, weight, kb_scaling, base_kb, 1)
		angle_flipper_func(body)
		body.knockback = knockback_value
		body.hitstun = get_hitstun(knockback_value / 0.3)
		get_parent().connected = true
		body.reset_frame()
		body.charge_frames = 0
		var charstate = body.get_node("StateMachine")
		charstate.set_state(charstate.states.HITSTUN)


func shield_ignore(body: CharacterBody2D):
	#if shield is disabled
	if body.shieldBoxShape.disabled:
		return true
	#get shieldbox shape
	var shield_shape := body.shieldBoxShape.shape as CircleShape2D
	if shield_shape == null:
		return false
	#get circular hurtbox shape
	var hurtbox_shape := body.hurtboxShape.shape as CircleShape2D
	if hurtbox_shape == null:
		return false
	#detect shieldpokes
	if hurtbox_shape.radius > shield_shape.radius:
		return true


func update_extents():
	if hitbox.shape == null:
		hitbox.shape = RectangleShape2D.new()
	hitbox.shape.extents = Vector2(width, height)


func _ready():
	if hitbox:
		var rect_shape = RectangleShape2D.new()
		rect_shape.extents = Vector2(width, height)
		hitbox.shape = rect_shape
	set_physics_process(false)
	pass


func _physics_process(delta):
	if hitbox_frames < duration:
		hitbox_frames += 1
	elif hitbox_frames == duration:
		Engine.time_scale = 1
		queue_free()
		return
	if get_parent().selfState != parentState:
		queue_free()
		return


#return increased hitstun based on knockback value
func get_hitstun(kb):
	return floor(kb * 0.5)


#knockback variables and formula
@export var percentage = 0
@export var weight = 100
@export var base_knockback = 40
@export var ratio = 1
func knockback(p, d, w, ks, bk, r):
	percentage = p
	damage = d
	weight = w
	kb_scaling = ks
	base_kb = bk
	ratio = r
	return (((((((p / 10) + (p * d / 20)) * (200 / (w + 100)) * 1.4) + 18) * ks) + bk) * r)


const angleConversion = PI / 180
# horizontal slow down rate after knockback
func getHorizontalDecay(angle):
	var decay = 0.051 * cos(angle * angleConversion) #Rate of decay is 0.051, to get horizontal rate; multiply by horizontal(cos) angle in radians
	decay = round(decay * 100000) / 100000 #Round to a whole number
	decay = decay * 1000 #Enlarge the rate of decay
	return decay
# vertical slow down rate after knockback
func getVerticalDecay(angle):
	var decay = 0.051 * sin(angle * angleConversion)
	decay = round(decay * 100000) / 100000
	decay = decay * 1000
	return abs(decay)
# gets the horizontal knockback speed with total knockback and angle
func getHorizontalVelocity(knockback, angle):
	var initialVelocity = knockback * 30 #Gets the initial velocity by multiplying knockback by 30
	var horizontalAngle = cos(angle * angleConversion) #Horizontal angle is calculated by cos formula, angle conversion puts the angle in radians
	var horizontalVelocity = initialVelocity * horizontalAngle #Horizontal velocity is found by multiplying initial velocity by horizontal angle
	horizontalVelocity = round(horizontalVelocity * 100000) / 100000 #Round to a whole number
	return horizontalVelocity;
func getVerticalVelocity(knockback, angle):
	var initialVelocity = knockback * 30;
	var verticalAngle = sin(angle * angleConversion);
	var verticalVelocity = initialVelocity * verticalAngle;
	verticalVelocity = round(verticalVelocity * 100000) / 100000;
	return verticalVelocity


#determines how the launch angle should be changed
func angle_flipper_func(body):
	var xangle
	if get_parent().direction() == -1:
		xangle = (-(((body.global_position.angle_to_point(get_parent().global_position)) * 180) / PI))
	else:
		xangle = (((body.global_position.angle_to_point(get_parent().global_position)) * 180) / PI)
	match angle_flipper:
		0:
			body.velocity.x = (getHorizontalVelocity(knockback_value, -angle))
			body.velocity.y = (getVerticalVelocity(knockback_value, -angle))
			body.hdecay = (getHorizontalDecay(angle))
			body.vdecay = (getVerticalDecay(angle))
