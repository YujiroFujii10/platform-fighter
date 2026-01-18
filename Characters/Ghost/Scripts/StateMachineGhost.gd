extends StateMachine
@onready var id = get_parent().id


func _ready():
	add_state('STAND')
	add_state('JUMP_SQUAT')
	add_state('SHORT_HOP')
	add_state('FULL_HOP')
	add_state('DASH')
	add_state('RUN')
	add_state('WALK')
	add_state('TURN')
	add_state('CROUCH')
	add_state('AIR')
	add_state('LANDING')
	add_state('LEDGE_CATCH')
	add_state('LEDGE_HOLD')
	add_state('LEDGE_CLIMB')
	add_state('LEDGE_JUMP')
	add_state('LEDGE_ROLL')
	add_state('HITSTUN')
	add_state('GROUND_ATTACK')
	add_state('DOWN_TILT')
	add_state('UP_TILT')
	add_state('FORWARD_TILT')
	add_state('JAB')
	add_state("DASH_ATTACK")
	add_state('AIR_ATTACK')
	add_state('DAIR')
	add_state('UAIR')
	add_state('FAIR')
	add_state('BAIR')
	add_state('NAIR')
	add_state('DOWN_SMASH_CHARGE')
	add_state('UP_SMASH_CHARGE')
	add_state('FORWARD_SMASH_CHARGE')
	add_state('DOWN_SMASH')
	add_state('UP_SMASH')
	add_state('FORWARD_SMASH')
	add_state('SHIELD')
	add_state('SPOT_DODGE')
	add_state('ROLL_RIGHT')
	add_state('ROLL_LEFT')
	add_state('AIR_DODGE')
	add_state('DOWN_SPECIAL')
	add_state('UP_SPECIAL')
	add_state('UP_SPECIAL_1')
	add_state('SIDE_SPECIAL')
	add_state('SIDE_SPECIAL_1')
	add_state('NEUTRAL_SPECIAL')
	add_state('RESPAWN')
	#IMPLEMENT GRAB
	add_state('GRAB')
	
	add_state('FREE_FALL')
	call_deferred("set_state", states.STAND)


func state_logic(delta):
	parent.update_frames(delta)
	parent._physics_process(delta)
	if parent.regrab > 0:
		parent.regrab -= 1


func get_transition(delta):
	
	#control enabled once countdown ends
	if not parent.input_enabled:
		return
	
	#respawn invincibility
	if parent.respawn_timer > 0:
		parent.respawn_timer -= 1
	elif parent.respawn_timer == 0 and not invincible_moves():
		parent.enable_hurtbox()
	#regen bubble shield passively
	if state != states.SHIELD and parent.shield_hp < 60:
		parent.shield_hp += parent.shield_regen
	
	#can't do anythihng if in hitstun
	if state != states.HITSTUN:
		if landing():
			return states.LANDING
		detect_all_wall_collisions()
		if falling():
			return states.AIR
		if ledge():
			parent.reset_frame()
			return states.LEDGE_CATCH
		else:
			parent.reset_ledge()
		#dash attack
		if Input.is_action_just_pressed("attack_%s" % id) and state_includes([states.DASH, states.RUN]):
				parent.reset_frame()
				parent.reset_hurtbox()
				return states.DASH_ATTACK
		#jab, tilts, smash attacks, grounded special
		elif (Input.is_action_just_pressed("attack_%s" % id) or Input.is_action_just_pressed("special_%s" % id)) and state_includes([states.STAND, states.CROUCH, states.WALK, states.DASH, states.RUN]):
			parent.reset_frame()
			parent.reset_hurtbox()
			return states.GROUND_ATTACK
		#aeriels, air specials
		elif (Input.is_action_just_pressed("attack_%s" % id) or Input.is_action_just_pressed("special_%s" % id)) and state_includes([states.AIR]):
			parent.reset_frame()
			parent.reset_hurtbox()
			return states.AIR_ATTACK
	
	parent.move_and_slide()
	
	match state:
		
		states.STAND:
			parent.reset_jumps()
			parent.reset_air_dodge()
			if Input.is_action_just_pressed("shield_%s" % id):
				parent.reset_frame()
				parent.shielding_hurtbox()
				return states.SHIELD
			if Input.get_action_strength("jump_%s" % id) and not Input.get_action_strength("light_%s" % id):
				parent.reset_frame()
				return states.JUMP_SQUAT
			if Input.get_action_strength("down_%s" % id):
				parent.reset_frame()
				return states.CROUCH
			#hold shift walk
			if Input.get_action_strength("right_%s" % id) == 1 and Input.is_action_pressed("light_%s" % id):
				parent.reset_frame()
				parent.turn(false)
				return states.WALK
			elif Input.get_action_strength("left_%s" % id) == 1 and Input.is_action_pressed("light_%s" % id):
				parent.reset_frame()
				parent.turn(true)
				return states.WALK
			#tap to dash
			elif Input.get_action_strength("right_%s" % id) == 1:
				parent.velocity.x = parent.RUNSPEED
				parent.reset_frame()
				parent.turn(false)
				return states.DASH
			if Input.get_action_strength("left_%s" % id) == 1:
				parent.velocity.x = -parent.RUNSPEED
				parent.reset_frame()
				parent.turn(true)
				return states.DASH
			if parent.velocity.x > 0 and state == states.STAND:
				parent.velocity.x += -parent.TRACTION*1
				parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0 and state == states.STAND:
				parent.velocity.x += parent.TRACTION*1
				parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
		
		states.JUMP_SQUAT:
			if parent.frame == parent.jump_squat:
				if not Input.is_action_pressed("jump_%s" % id):
					parent.velocity.x = lerpf(parent.velocity.x, 0, 0.88)
					parent.reset_frame()
					return states.SHORT_HOP
				else:
					parent.velocity.x = lerpf(parent.velocity.x, 0, 0.8)
					parent.reset_frame()
					return states.FULL_HOP
		
		states.SHORT_HOP:
			parent.velocity.y = -parent.JUMPFORCE
			parent.reset_frame()
			return states.AIR
		
		states.FULL_HOP:
			parent.velocity.y = -parent.MAX_JUMPFORCE
			parent.reset_frame()
			return states.AIR
		
		states.DASH:
			#allows jumping from dashing
			if Input.get_action_strength("jump_%s" % id) and not Input.get_action_strength("light_%s" % id):
				parent.reset_frame()
				return states.JUMP_SQUAT
			elif Input.is_action_pressed("left_%s" % id):
				if parent.velocity.x > 0:
					parent.reset_frame()
				parent.velocity.x = -parent.DASHSPEED
				if parent.frame <= parent.dash_duration-1:
					parent.turn(true)
					return states.DASH
				else:
					parent.turn(true)
					parent.reset_frame()
					return states.RUN
			elif Input.is_action_pressed("right_%s" % id):
				if parent.velocity.x < 0:
					parent.reset_frame()
				parent.velocity.x =parent.DASHSPEED
				if parent.frame <= parent.dash_duration-1:
					parent.turn(false)
					return states.DASH
				else:
					parent.turn(false)
					parent.reset_frame()
					return states.RUN
			else:
				if parent.frame >= parent.dash_duration-1:
					return states.STAND
		
		states.RUN:
			if Input.is_action_just_pressed("shield_%s" % id):
				parent.reset_frame()
				parent.shielding_hurtbox()
				return states.SHIELD
			if Input.is_action_just_pressed("jump_%s" % id) and not Input.get_action_strength("light_%s" % id):
				parent.reset_frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_pressed("down_%s" % id):
				parent.reset_frame()
				return states.CROUCH
			if Input.get_action_strength("right_%s" % id) == 1 and Input.is_action_pressed("light_%s" % id):
				parent.reset_frame()
				parent.turn(false)
				return states.WALK
			if Input.get_action_strength("left_%s" % id) == 1 and Input.is_action_pressed("light_%s" % id):
				parent.reset_frame()
				parent.turn(true)
				return states.WALK
			if Input.get_action_strength("left_%s" % id):
				if parent.velocity.x <= 0:
					parent.velocity.x = -parent.RUNSPEED
					parent.turn(true)
				else:
					parent.reset_frame()
					return states.TURN
			elif Input.get_action_strength("right_%s" % id):
				if parent.velocity.x >= 0:
					parent.velocity.x = parent.RUNSPEED
					parent.turn(false)
				else:
					parent.reset_frame()
					return states.TURN
			else:
				parent.reset_frame()
				return states.STAND
		
		states.WALK:
			if Input.is_action_just_pressed("shield_%s" % id):
				parent.reset_frame()
				parent.shielding_hurtbox()
				return states.SHIELD
			if Input.is_action_just_pressed("jump_%s" % id) and not Input.get_action_strength("light_%s" % id):
				parent.reset_frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_pressed("down_%s" % id):
				parent.reset_frame()
				return states.CROUCH
			if (Input.is_action_pressed("left_%s" % id) and Input.is_action_pressed("light_%s" % id)):
				parent.velocity.x = -parent.WALKSPEED
				parent.turn(true)
			elif (Input.is_action_pressed("right_%s" % id) and Input.is_action_pressed("light_%s" % id)):
				parent.velocity.x = parent.WALKSPEED
				parent.turn(false)
			else:
				parent.reset_frame()
				return states.STAND
		
		states.TURN:
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.reset_frame()
				return states.JUMP_SQUAT
			if parent.velocity.x > 0:
				parent.turn(true)
				parent.velocity.x += -parent.TRACTION * 2
				parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0:
				parent.turn(false)
				parent.velocity.x += parent.TRACTION * 2
				parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
			else:
				if not Input.is_action_pressed("left_%s" % id) and not Input.is_action_pressed("right_%s" % id):
					parent.reset_frame()
					return states.STAND
				else:
					parent.reset_frame()
					return states.RUN
		
		states.CROUCH:
			parent.set_crouch_hurtbox()
			if Input.is_action_just_pressed("shield_%s" % id):
				parent.reset_frame()
				parent.shielding_hurtbox()
				return states.SHIELD
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.reset_frame()
				parent.reset_hurtbox()
				return states.JUMP_SQUAT
			if Input.is_action_just_released("down_%s" % id):
				parent.reset_frame()
				parent.reset_hurtbox()
				return states.STAND
			elif parent.velocity.x > 0:
				if parent.velocity.x > parent.RUNSPEED:
					parent.velocity.x += -(parent.TRACTION * 4)
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				else:
					parent.velocity.x += -(parent.TRACTION / 2)
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0:
				if abs(parent.velocity.x) > parent.RUNSPEED:
					parent.velocity.x += (parent.TRACTION * 4)
					parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
				else:
					parent.velocity.x += (parent.TRACTION / 2)
					parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
		
		states.AIR:
			air_movement()
			if Input.is_action_just_pressed("jump_%s" % id) and parent.air_jump > 0:
				parent.fastfall = false
				parent.velocity.x = 0
				parent.velocity.y = -parent.DOUBLEJUMPFORCE
				parent.air_jump -= 1
				if Input.is_action_pressed("left_%s" % id):
					parent.velocity.x = -parent.MAXAIRSPEED
				elif Input.is_action_pressed("right_%s" % id):
					parent.velocity.x = parent.MAXAIRSPEED
			elif Input.is_action_just_pressed("shield_%s" % id) and parent.air_dodge > 0:
				parent.reset_frame()
				return states.AIR_DODGE
		
		states.LANDING:
			if parent.frame <= parent.landing_frames + parent.lag_frames:
				if parent.frame == 1:
					pass
				if parent.velocity.x > 0:
					parent.velocity.x = parent.velocity.x - parent.TRACTION / 2
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x = parent.velocity.x + parent.TRACTION / 2
					parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
				if Input.is_action_just_pressed("jump_%s" % id) and Input.is_action_pressed("shield"):
					parent.reset_frame()
					return states.JUMP_SQUAT
			else:
				if Input.is_action_pressed("down_%s" % id):
					parent.lag_frames = 0
					parent.reset_frame()
					parent.reset_jumps()
					parent.reset_air_dodge()
					return states.CROUCH
				else:
					parent.reset_frame()
					parent.lag_frames = 0
					parent.reset_jumps()
					parent.reset_air_dodge()
					return states.STAND
			parent.lag_frames = 0
		
		states.LEDGE_CATCH:
			if parent.frame > 7:
				parent.disable_hurtbox()
				parent.lag_frames = 0
				parent.reset_jumps()
				parent.reset_air_dodge()
				parent.reset_frame()
				return states.LEDGE_HOLD
		
		states.LEDGE_HOLD:
			#60 frames of ledge invincibility
			if parent.frame >= 60:
				parent.enable_hurtbox()
			#drop if ledge hold for 390 frames
			if parent.frame >= 390:
				parent.regrab = 30
				parent.reset_frame()
				return states.AIR
			
			if Input.is_action_just_pressed("down_%s" % id):
				parent.enable_hurtbox()
				parent.fastfall = true
				parent.regrab = 30
				parent.reset_ledge()
				self.parent.position.y += -10
				parent.catch = false
				parent.reset_frame()
				return states.AIR
			#facing right
			var out_input = "left_%s" % id 
			var in_input = "right_%s" % id 
			#facing left
			if parent.LedgeGrabF.target_position.x < 0:
				out_input = "right_%s" % id
				in_input = "left_%s" % id
			if Input.is_action_just_pressed(out_input):
				parent.enable_hurtbox()
				parent.velocity.x = parent.AIR_ACCEL / 2
				parent.regrab = 30
				parent.reset_ledge()
				self.parent.position.y -= 10
				parent.catch = false
				parent.reset_frame()
				return states.AIR
			if Input.is_action_just_pressed(in_input):
				parent.disable_hurtbox()
				parent.reset_frame()
				return states.LEDGE_CLIMB
			if Input.is_action_just_pressed("shield_%s" % id):
				parent.disable_hurtbox()
				parent.reset_frame()
				return states.LEDGE_ROLL
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.disable_hurtbox()
				parent.reset_frame()
				return states.LEDGE_JUMP
		
		states.LEDGE_CLIMB:
			if parent.frame == 1:
				pass
			if parent.frame == 5:
				parent.position.y -= 30
			if parent.frame == 10:
				parent.position.y -= 30
			if parent.frame == 20:
				parent.position.y -= 30
			if parent.frame == 22:
				parent.catch = false
				parent.position.y -= 30
				parent.position.x += 50 * parent.direction()
			if parent.frame == 25:
				parent.enable_hurtbox()
				parent.velocity.y = 0
				parent.velocity.x = 0
				parent.move_and_collide(Vector2(parent.direction() * 20, 50))
			if parent.frame == 30:
				parent.reset_ledge()
				parent.reset_frame()
				return states.STAND
		
		states.LEDGE_JUMP:
			if parent.frame > 14:
				if Input.is_action_just_pressed("attack_%s" % id):
					parent.enable_hurtbox()
					parent.reset_frame()
					return states.AIR_ATTACK
				if Input.is_action_just_pressed("special_%s" % id):
					parent.enable_hurtbox()
					parent.reset_frame()
					return states.AIR_ATTACK
			if parent.frame == 5:
				parent.reset_ledge()
				parent.position.y -= 20
			if parent.frame == 10:
				parent.catch = false
				parent.position.y -= 20
				if Input.is_action_just_pressed("jump_%s" % id) and parent.air_jump > 0:
					parent.enable_hurtbox()
					parent.fastfall = false
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.velocity.x = 0
					parent.air_jump -= 1
					parent.reset_frame()
					return states.AIR
			if parent.frame == 15:
				parent.position.y -= 20
				parent.velocity.y -= parent.DOUBLEJUMPFORCE
				parent.velocity.x += 220 * parent.direction()
				if Input.is_action_just_pressed("jump_%s" % id) and parent.air_jump > 0:
					parent.enable_hurtbox()
					parent.fastfall = false
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.velocity.x = 0
					parent.air_jump -= 1
					parent.reset_frame()
					return states.AIR
				if Input.is_action_just_pressed("attack_%s" % id):
					parent.enable_hurtbox()
					parent.reset_frame()
					return states.AIR_ATTACK
			elif parent.frame > 15 and parent.frame < 20:
				parent.velocity.y += parent.FALLSPEED
				if Input.is_action_just_pressed("jump_%s" % id) and parent.air_jump > 0:
					parent.enable_hurtbox()
					parent.fastfall = false
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.velocity.x = 0
					parent.air_jump -= 1
					parent.reset_frame()
					return states.AIR
					if Input.is_action_just_pressed("attack" % id):
						parent.enable_hurtbox()
						parent.reset_frame()
						return states.AIR_ATTACK
			if parent.frame == 20:
				parent.enable_hurtbox()
				parent.reset_frame()
				return states.AIR
		
		states.LEDGE_ROLL:
			if parent.frame == 1:
				pass
			if parent.frame == 5:
				parent.position.y -= 30
			if parent.frame == 10:
				parent.position.y -= 30
			if parent.frame == 20:
				parent.catch = false
				parent.position.y -= 30
			if parent.frame == 22:
				parent.position.y -= 30
				parent.position.x += 50 * parent.direction()
			if parent.frame > 22 and parent.frame < 28:
				parent.position.x += 30 * parent.direction()
			if parent.frame == 29:
				parent.enable_hurtbox()
				parent.move_and_collide(Vector2(parent.direction()*20, 50))
			if parent.frame == 33:
				parent.velocity.y = 0
				parent.velocity.x = 0
				parent.reset_ledge()
				parent.reset_frame()
				return states.STAND
		
		states.HITSTUN:
			parent.disable_shield()
			parent.reset_hurtbox()
			parent.charge_frames = 0
			if parent.knockback >= 1:
				var collision: KinematicCollision2D = parent.move_and_collide(parent.velocity * delta)
				if collision != null:
					# Bounce off the surface
					parent.velocity = parent.velocity.bounce(collision.get_normal()) * 0.8
					parent.hitstun = round(parent.hitstun * 0.8)
			# Vertical velocity decay (only applies when moving upward)
			if parent.velocity.y < 0:
				parent.velocity.y += parent.vdecay * 0.5 * Engine.time_scale
				parent.velocity.y = clamp(parent.velocity.y, parent.velocity.y, 0)
			# Horizontal velocity decay
			if parent.velocity.x < 0:
				parent.velocity.x += parent.hdecay * 0.4 * -1 * Engine.time_scale
				parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
			elif parent.velocity.x > 0:
				parent.velocity.x -= parent.hdecay * 0.4 * Engine.time_scale
				parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
			# End HITSTUN when frame reaches hitstun duration or very long
			if parent.frame >= parent.hitstun or parent.frame > 240:
				parent.reset_frame()
				return states.AIR
		
		states.GROUND_ATTACK:
			#specials
			if Input.is_action_pressed("special_%s" % id):
				if Input.is_action_pressed("up_%s" % id):
					parent.reset_frame()
					return states.UP_SPECIAL
				elif Input.is_action_pressed("down_%s" % id):
					parent.reset_frame()
					return states.DOWN_SPECIAL
				elif Input.is_action_pressed("left_%s" % id):
					parent.turn(true)
					parent.reset_frame()
					return states.SIDE_SPECIAL
				elif Input.is_action_pressed("right_%s" % id):
					parent.turn(false)
					parent.reset_frame()
					return states.SIDE_SPECIAL
				else:
					parent.reset_frame()
					return states.NEUTRAL_SPECIAL
			#tilts
			if Input.is_action_pressed("light_%s" % id) or Input.get_action_strength("attack_%s" % id) < 0.8:
				#up tilt commands allowing instant turnaround
				if Input.is_action_pressed("up_%s" % id) and Input.is_action_pressed("left_%s" % id):
					parent.turn(true)
					parent.reset_frame()
					return states.UP_TILT
				elif Input.is_action_pressed("up_%s" % id) and Input.is_action_pressed("right_%s" % id):
					parent.turn(false)
					parent.reset_frame()
					return states.UP_TILT
				elif Input.is_action_pressed("up_%s" % id):
					parent.reset_frame()
					return states.UP_TILT
				#down tilt commands allowing instant turnaround
				elif Input.is_action_pressed("down_%s" % id) and Input.is_action_pressed("left_%s" % id):
					parent.turn(true)
					parent.reset_frame()
					return states.DOWN_TILT
				elif Input.is_action_pressed("down_%s" % id) and Input.is_action_pressed("right_%s" % id):
					parent.turn(false)
					parent.reset_frame()
					return states.DOWN_TILT
				elif Input.is_action_pressed("down_%s" % id):
					parent.reset_frame()
					return states.DOWN_TILT
				#forward tilt commands
				elif Input.is_action_pressed("left_%s" % id):
					parent.turn(true)
					parent.reset_frame()
					return states.FORWARD_TILT
				elif Input.is_action_pressed("right_%s" % id):
					parent.turn(false)
					parent.reset_frame()
					return states.FORWARD_TILT
				#jab
				parent.reset_frame()
				return states.JAB
			#smash attacks
			if Input.is_action_pressed("attack_%s" % id):
				if Input.is_action_pressed("up_%s" % id):
					parent.reset_frame()
					return states.UP_SMASH_CHARGE
				elif Input.is_action_pressed("down_%s" % id):
					parent.reset_frame()
					return states.DOWN_SMASH_CHARGE
				elif Input.is_action_pressed("left_%s" % id):
					parent.turn(true)
					parent.reset_frame()
					return states.FORWARD_SMASH_CHARGE
				elif Input.is_action_pressed("right_%s" % id):
					parent.turn(false)
					parent.reset_frame()
					return states.FORWARD_SMASH_CHARGE
				#jab
				parent.reset_frame()
				return states.JAB
		
		states.DOWN_TILT:
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			if parent.down_tilt():
				if Input.is_action_just_pressed("down_%s" % id):
					parent.reset_frame()
					return states.CROUCH
				else:
					parent.reset_frame()
					return states.STAND
		
		states.UP_TILT:
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			if parent.up_tilt():
				parent.reset_frame()
				return states.STAND
		
		states.FORWARD_TILT:
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			if parent.forward_tilt():
				#hold shift walk
				if Input.get_action_strength("right_%s" % id) == 1 and Input.is_action_pressed("light_%s" % id):
					parent.reset_frame()
					parent.turn(false)
					return states.WALK
				elif Input.get_action_strength("left_%s" % id) == 1 and Input.is_action_pressed("light_%s" % id):
					parent.reset_frame()
					parent.turn(true)
					return states.WALK
				#dash
				if Input.get_action_strength("right_%s" % id) == 1:
					parent.velocity.x = parent.RUNSPEED
					parent.reset_frame()
					parent.turn(false)
					return states.DASH
				if Input.get_action_strength("left_%s" % id) == 1:
					parent.velocity.x = -parent.RUNSPEED
					parent.reset_frame()
					parent.turn(true)
					return states.DASH
				else:
					parent.reset_frame()
					return states.STAND
		
		states.JAB:
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			if parent.jab():
				parent.reset_frame()
				return states.STAND
		
		states.DASH_ATTACK:
			if parent.frame >= 1:
				var decel = parent.TRACTION * 0.28
				if parent.velocity.x > 0:
					parent.velocity.x = maxf(parent.velocity.x - decel, 0)
				elif parent.velocity.x < 0:
					parent.velocity.x = minf(parent.velocity.x + decel, 0)
			if parent.dash_attack():
				if Input.get_action_strength("right_%s" % id) == 1:
					parent.velocity.x = parent.RUNSPEED
					parent.reset_frame()
					parent.turn(false)
					return states.DASH
				if Input.get_action_strength("left_%s" % id) == 1:
					parent.velocity.x = -parent.RUNSPEED
					parent.reset_frame()
					parent.turn(true)
					return states.DASH
				else:
					parent.reset_frame()
					return states.STAND
		
		states.DOWN_SMASH_CHARGE:
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			if not Input.is_action_pressed("attack_%s" % id) or parent.frame >= 60:
				parent.charge_frames = parent.frame
				parent.reset_frame()
				return states.DOWN_SMASH
		
		states.UP_SMASH_CHARGE:
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			if not Input.is_action_pressed("attack_%s" % id) or parent.frame >= 60:
				parent.charge_frames = parent.frame
				parent.reset_frame()
				return states.UP_SMASH
		
		states.FORWARD_SMASH_CHARGE:
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			if not Input.is_action_pressed("attack_%s" % id) or parent.frame >= 60:
				parent.charge_frames = parent.frame
				parent.reset_frame()
				return states.FORWARD_SMASH
		
		states.DOWN_SMASH:
			if parent.down_smash(parent.charge_frames):
				parent.charge_frames = 0
				if Input.is_action_just_pressed("down_%s" % id):
					parent.reset_frame()
					return states.CROUCH
				else:
					parent.reset_frame()
					return states.STAND
		
		states.UP_SMASH:
			if parent.up_smash(parent.charge_frames):
				parent.charge_frames = 0
				parent.reset_frame()
				return states.STAND
		
		states.FORWARD_SMASH:
			if parent.direction() == 1 and parent.frame <= 25:
				parent.velocity.x += 20
			elif parent.direction() == 1 and parent.frame == 26:
				parent.velocity.x = -30
			if parent.direction() == -1 and parent.frame <= 25:
				parent.velocity.x -= 20
			elif parent.direction() == -1 and parent.frame == 26:
				parent.velocity.x = 30
			if parent.forward_smash(parent.charge_frames):
				parent.charge_frames = 0
				#hold shift walk
				if Input.get_action_strength("right_%s" % id) == 1 and Input.is_action_pressed("light_%s" % id):
					parent.reset_frame()
					parent.turn(false)
					return states.WALK
				elif Input.get_action_strength("left_%s" % id) == 1 and Input.is_action_pressed("light_%s" % id):
					parent.reset_frame()
					parent.turn(true)
					return states.WALK
				#dash
				if Input.get_action_strength("right_%s" % id) == 1:
					parent.velocity.x = parent.RUNSPEED
					parent.reset_frame()
					parent.turn(false)
					return states.DASH
				if Input.get_action_strength("left_%s" % id) == 1:
					parent.velocity.x = -parent.RUNSPEED
					parent.reset_frame()
					parent.turn(true)
					return states.DASH
				else:
					parent.reset_frame()
					return states.STAND
		
		states.AIR_ATTACK:
			air_movement()
			#specials
			if Input.is_action_pressed("special_%s" % id):
				if Input.is_action_pressed("down_%s" % id):
					parent.reset_frame()
					return states.DOWN_SPECIAL
				elif Input.is_action_pressed("up_%s" % id):
					parent.reset_frame()
					return states.UP_SPECIAL
				elif Input.is_action_pressed("left_%s" % id):
					parent.turn(true)
					parent.reset_frame()
					return states.SIDE_SPECIAL
				elif Input.is_action_pressed("right_%s" % id):
					parent.turn(false)
					parent.reset_frame()
					return states.SIDE_SPECIAL
				else:
					parent.reset_frame()
					return states.NEUTRAL_SPECIAL
			if Input.is_action_pressed("down_%s" % id):
				parent.reset_frame()
				return states.DAIR
			if parent.direction() == 1:
					if Input.is_action_pressed("left_%s" % id):
						parent.reset_frame()
						return states.BAIR
					elif Input.is_action_pressed("right_%s" % id):
						parent.reset_frame()
						return states.FAIR
			elif parent.direction() == -1:
					if Input.is_action_pressed("right_%s" % id):
						parent.reset_frame()
						return states.BAIR
					elif Input.is_action_pressed("left_%s" % id):
						parent.reset_frame()
						return states.FAIR
			if Input.is_action_pressed("up_%s" % id):
				parent.reset_frame()
				return states.UAIR
			parent.reset_frame()
			return states.NAIR
		
		states.DAIR:
			air_movement()
			if parent.down_air() == true:
				parent.lag_frames = 0
				parent.reset_frame()
				return states.AIR
		
		states.UAIR:
			air_movement()
			if parent.up_air() == true:
				parent.lag_frames = 0
				parent.reset_frame()
				return states.AIR
		
		states.FAIR:
			air_movement()
			if parent.forward_air() == true:
				parent.lag_frames = 0
				parent.reset_frame()
				return states.AIR
		
		states.BAIR:
			air_movement()
			if parent.back_air() == true:
				parent.lag_frames = 0
				parent.reset_frame()
				return states.AIR
		
		states.NAIR:
			air_movement()
			if parent.neutral_air() == true:
				parent.lag_frames = 0
				parent.reset_frame()
				return states.AIR
		
		states.SHIELD:
			parent.bubble_shield()
			parent.shielding_hurtbox()
			parent.shield_hp -= parent.shield_decay
			if parent.velocity.x > 0:
				parent.velocity.x += -parent.TRACTION * 3
				parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0:
				parent.velocity.x += parent.TRACTION * 3
				parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			#spot dodge
			if Input.is_action_pressed("shield_%s" % id) and Input.is_action_pressed("down_%s" % id):
				parent.disable_shield()
				parent.reset_hurtbox()
				parent.reset_frame()
				return states.SPOT_DODGE
				pass
			#jump
			if Input.is_action_pressed("up_%s" % id):
				parent.disable_shield()
				parent.reset_hurtbox()
				parent.reset_frame()
				return states.JUMP_SQUAT
				pass
			#roll left
			elif Input.is_action_pressed("shield_%s" % id) and Input.is_action_pressed("left_%s" % id):
				parent.disable_shield()
				parent.reset_hurtbox()
				parent.reset_frame()
				return states.ROLL_LEFT
				pass
			#roll right
			elif Input.is_action_pressed("shield_%s" % id) and Input.is_action_pressed("right_%s" % id):
				parent.disable_shield()
				parent.reset_hurtbox()
				parent.reset_frame()
				return states.ROLL_RIGHT
				pass
			#shield break
			elif Input.is_action_pressed("shield_%s" % id) and parent.shield_hp <= 0:
				parent.disable_shield()
				parent.reset_hurtbox()
				parent.reset_frame()
				parent.velocity.y = -4000
				return states.AIR
				pass
			#release shield
			elif not Input.is_action_pressed("shield_%s" % id):
				parent.disable_shield()
				parent.reset_hurtbox()
				parent.reset_frame()
				return states.STAND
		
		states.SPOT_DODGE:
			if parent.frame == 3:
				parent.disable_hurtbox()
			elif parent.frame == 30:
				parent.enable_hurtbox()
			elif parent.frame >= 33:
				return states.STAND
		
		states.ROLL_RIGHT:
			parent.turn(true)
			if parent.frame == 1:
				parent.velocity.x = 0
			if parent.frame == 4:
				parent.velocity.x = parent.ROLL_DISTANCE
				parent.disable_hurtbox()
			if parent.frame == 20:
				parent.enable_hurtbox()
			if parent.frame >= 20:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				if parent.velocity.x == 0:
					parent.reset_frame()
					return states.STAND
		
		states.ROLL_LEFT:
			parent.turn(false)
			if parent.frame == 1:
				parent.velocity.x = 0
			if parent.frame == 4:
				parent.velocity.x -= parent.ROLL_DISTANCE
				parent.disable_hurtbox()
			if parent.frame == 20:
				parent.enable_hurtbox()
			if parent.frame >= 20:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION * 3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				if parent.velocity.x == 0:
					parent.reset_frame()
					return states.STAND
		
		states.AIR_DODGE:
			parent.air_dodge -= 1
			if parent.frame == 1:
				var input_vector = Vector2(Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id), Input.get_action_strength("down_%s" % id) - Input.get_action_strength("up_%s" % id))
				parent.air_dodge_input = input_vector
				var direction = input_vector.normalized()
				parent.velocity = direction * parent.AIR_DODGE_SPEED
			elif parent.frame >= 3 and parent.frame <= 40:
				parent.disable_hurtbox()
				if parent.frame == 15:
					parent.velocity = Vector2(0,0)
			if parent.frame >= 41:
				air_movement()
				parent.enable_hurtbox()
			if parent.frame == 50 and parent.air_dodge_input == Vector2(0, 0):
				parent.reset_frame()
				return states.AIR
			if parent.frame == 60 and parent.air_dodge_input != Vector2(0, 0):
				parent.reset_frame()
				return states.AIR
		
		states.DOWN_SPECIAL:
			if parent.frame == 1:
				parent.velocity = Vector2.ZERO
			if parent.frame >= 16 and parent.frame <= 18:
				parent.velocity.y += 400
			if parent.down_special():
				return states.AIR
		
		states.UP_SPECIAL:
			parent.velocity = Vector2.ZERO
			if parent.frame >= 60:
				parent.reset_frame()
				return states.UP_SPECIAL_1
		
		states.UP_SPECIAL_1:
			if Input.is_action_pressed("left_%s" % id):
				parent.velocity.x = -parent.MAXAIRSPEED
			elif Input.is_action_pressed("right_%s" % id):
				parent.velocity.x = parent.MAXAIRSPEED
			if parent.frame == 1:
				parent.velocity.y = -parent.UP_B_LAUNCHSPEED
			if parent.up_special():
				parent.velocity.x = 0
				parent.velocity.y = 0
				parent.reset_frame()
				return states.FREE_FALL
		
		states.SIDE_SPECIAL:
			if parent.frame == 1:
				parent.velocity = Vector2.ZERO
			if parent.frame >= 5 and parent.frame <= 25:
				parent.velocity.y += 20
			if parent.frame >= 14 and (not Input.is_action_pressed("special_%s" % id) or parent.frame >= 100):
				parent.velocity.y = 0
				parent.charge_frames = parent.frame
				parent.reset_frame()
				return states.SIDE_SPECIAL_1
		
		states.SIDE_SPECIAL_1:
			if Input.is_action_pressed("up_%s" % id):
				parent.velocity.y -= 50
			elif Input.is_action_pressed("down_%s" % id):
				parent.velocity.y += 50
			if parent.frame == 1:
				if parent.direction() == 1:
					parent.velocity.x = (parent.SIDE_B_LAUNCHSPEED * ((parent.charge_frames * 0.008) + 1))
				elif parent.direction() == -1:
					parent.velocity.x -= (parent.SIDE_B_LAUNCHSPEED * ((parent.charge_frames * 0.008) + 1))
			if parent.side_special(parent.charge_frames):
				parent.velocity.x = 0
				parent.velocity.y = 0
				parent.charge_frames = 0
				parent.reset_frame()
				return states.FREE_FALL
		
		states.NEUTRAL_SPECIAL:
			if parent.frame == 1:
				parent.velocity.x = 0
				parent.velocity.y = 0
			elif parent.frame >= 2:
				air_movement()
			if parent.neutral_special():
				if Input.is_action_just_pressed("special_%s" % id):
					parent.reset_frame()
					return states.NEUTRAL_SPECIAL
				elif state_includes([states.AIR]):
					return states.AIR
				else:
					parent.reset_frame()
					return states.STAND
		
		states.FREE_FALL:
			air_movement()
			if landing():
				return states.LANDING
		
		states.RESPAWN:
			parent.respawn_timer = 120
			parent.reset_jumps()
			parent.reset_air_dodge()
			parent.reset_ledge()
			parent.reset_frame()
			parent.reset_hurtbox()
			parent.disable_hurtbox()
			return states.AIR


func invincible_moves():
	if state_includes([states.SPOT_DODGE, states.ROLL_RIGHT, states.ROLL_LEFT, states.AIR_DODGE, states.LEDGE_ROLL, states.LEDGE_JUMP, states.LEDGE_CLIMB, states.LEDGE_HOLD, states.LEDGE_CATCH, states.DOWN_SPECIAL]):
		return true
	return false


func enter_state(new_state, old_state):
	match new_state:
		states.STAND:
			parent.play_animation("Idle")
			parent.states.text = str("Idle")
		states.DASH:
			parent.play_animation("Dash")
			parent.states.text = str("Dash")
		states.TURN:
			parent.play_animation("Turn")
			parent.states.text = str("Turn")
		states.CROUCH:
			parent.play_animation("Crouch")
			parent.states.text = str("Crouch")
		states.RUN:
			parent.play_animation("Run")
			parent.states.text = str("Run")
		states.WALK:
			parent.play_animation("Walk")
			parent.states.text = str("Walk")
		states.JUMP_SQUAT:
			parent.play_animation("JumpSquat")
			parent.states.text = str("JumpSquat")
		states.SHORT_HOP:
			parent.play_animation("Air")
			parent.states.text = str("ShortHop")
		states.FULL_HOP:
			parent.play_animation("Air")
			parent.states.text = str("FullHop")
		states.AIR:
			parent.play_animation("Air")
			parent.states.text = str("Air")
		states.LANDING:
			parent.play_animation("Landing")
			parent.states.text = str("Landing")
		states.LEDGE_CATCH:
			parent.play_animation("LedgeHang")
			parent.states.text = str("LedgeCatch")
		states.LEDGE_HOLD:
			parent.play_animation("LedgeHang")
			parent.states.text = str("LedgeHold")
		states.LEDGE_JUMP:
			parent.play_animation("Air")
			parent.states.text = str("LedgeJump")
		states.LEDGE_CLIMB:
			parent.play_animation("RollForward")
			parent.states.text = str("LedgeClimb")
		states.LEDGE_ROLL:
			parent.play_animation("RollForward")
			parent.states.text = str("LedgeRoll")
		states.HITSTUN:
			parent.play_animation("Hitstun")
			parent.states.text = str("Hitstun")
		states.GROUND_ATTACK:
			parent.states.text = str("GroundAttack")
		states.DOWN_TILT:
			parent.play_animation("DownTilt")
			parent.states.text = str("DownTilt")
		states.UP_TILT:
			parent.play_animation("UpTilt")
			parent.states.text = str("UpTilt")
		states.FORWARD_TILT:
			parent.play_animation("ForwardTilt")
			parent.states.text = str("ForwardTilt")
		states.JAB:
			parent.play_animation("Jab")
			parent.states.text = str("Jab")
		states.DASH_ATTACK:
			parent.play_animation("DashAttack")
			parent.states.text = str("DashAttack")
		states.AIR_ATTACK:
			parent.states.text = str("AirAttack")
		states.DAIR:
			parent.play_animation("Dair")
			parent.states.text = str("Dair")
		states.UAIR:
			parent.play_animation("Uair")
			parent.states.text = str("Uair")
		states.FAIR:
			parent.play_animation("Fair")
			parent.states.text = str("Fair")
		states.BAIR:
			parent.play_animation("Bair")
			parent.states.text = str("Bair")
		states.NAIR:
			parent.play_animation("Nair")
			parent.states.text = str("Nair")
		states.DOWN_SMASH_CHARGE:
			parent.play_animation("DownSmashCharge")
			parent.states.text = str("DownSmashCharge")
		states.UP_SMASH_CHARGE:
			parent.play_animation("UpSmashCharge")
			parent.states.text = str("UpSmashCharge")
		states.FORWARD_SMASH_CHARGE:
			parent.play_animation("ForwardSmashCharge")
			parent.states.text = str("ForwardSmashCharge")
		states.DOWN_SMASH:
			parent.play_animation("DownSmash")
			parent.states.text = str("DownSmash")
		states.UP_SMASH:
			parent.play_animation("UpSmash")
			parent.states.text = str("UpSmash")
		states.FORWARD_SMASH:
			parent.play_animation("ForwardSmash")
			parent.states.text = str("ForwardSmash")
		states.SHIELD:
			parent.play_animation("Shield")
			parent.states.text = str("Shield")
		states.SPOT_DODGE:
			parent.play_animation("SpotDodge")
			parent.states.text = str("SpotDodge")
		states.ROLL_RIGHT:
			parent.play_animation("RollForward")
			parent.states.text = str("RollRight")
		states.ROLL_LEFT:
			parent.play_animation("RollForward")
			parent.states.text = str("RollLeft")
		states.AIR_DODGE:
			parent.play_animation("AirDodge")
			parent.states.text = str("AirDodge")
		states.DOWN_SPECIAL:
			parent.play_animation("DownSpecial")
			parent.states.text = str("DownSpecial")
		states.UP_SPECIAL:
			parent.play_animation("UpSpecial")
			parent.states.text = str("UpSpecialCharge")
		states.UP_SPECIAL_1:
			parent.play_animation("UpSpecial1")
			parent.states.text = str("UpSpecial1")
		states.SIDE_SPECIAL:
			parent.play_animation("SideSpecial")
			parent.states.text = str("SideSpecialCharge")
		states.SIDE_SPECIAL_1:
			parent.play_animation("SideSpecial1")
			parent.states.text = str("SideSpecial1")
		states.NEUTRAL_SPECIAL:
			parent.play_animation("NeutralSpecial")
			parent.states.text = str("NeutralSpecial")
		states.FREE_FALL:
			parent.play_animation("FreeFall")
			parent.states.text = str("FreeFall")


func exit_state(old_state, new_state):
	pass


func state_includes(state_array):
	for each_state in state_array:
		if state == each_state:
			return true
	return false


func air_movement():
	if not parent.input_enabled:
		return
	if parent.velocity.y < parent.FALLINGSPEED:
		parent.velocity.y += parent.FALLSPEED
	if Input.is_action_pressed("down_%s" % id) and parent.velocity.y > -150 and not parent.fastfall:
		parent.velocity.y = parent.MAXFALLSPEED
		parent.fastfall = true
	if parent.fastfall == true:
		parent.collision_mask &= ~(1 << 2)
		parent.velocity.y = parent.MAXFALLSPEED
	if abs(parent.velocity.x) >= abs(parent.MAXAIRSPEED):
		if parent.velocity.x > 0:
			if Input.is_action_pressed("left_%s" % id):
				parent.velocity.x += -parent.AIR_ACCEL
			elif Input.is_action_pressed("right_%s" % id):
				parent.velocity.x = parent.velocity.x
		if parent.velocity.x < 0:
			if Input.is_action_pressed("left_%s" % id):
				parent.velocity.x = parent.velocity.x
			elif Input.is_action_pressed("right_%s" % id):
				parent.velocity.x += parent.AIR_ACCEL
	elif abs(parent.velocity.x) < abs(parent.MAXAIRSPEED):
		if Input.is_action_pressed("left_%s" % id):
			parent.velocity.x += -parent.AIR_ACCEL * 2
		if Input.is_action_pressed("right_%s" % id):
			parent.velocity.x += parent.AIR_ACCEL * 2
	if not Input.is_action_pressed("left_%s" % id) and not Input.is_action_pressed("right_%s" % id):
		if parent.velocity.x < 0:
			parent.velocity.x += parent.AIR_ACCEL / 5
		elif parent.velocity.x > 0:
			parent.velocity.x += -parent.AIR_ACCEL / 5


func detect_all_wall_collisions():
	# Get delta for this frame
	var delta = get_physics_process_delta_time()
	var half_width = parent.get_node("CollisionBox").shape.extents.x
	var half_height = parent.get_node("CollisionBox").shape.extents.y
	# Track the closest collisions
	var closest_ceiling_y := -INF
	var closest_left_x := -INF
	var closest_right_x := INF
	# Ceiling
	for ray in [parent.CeilingL, parent.CeilingR]:
		var rise_dist = maxf(-parent.velocity.y * delta, 8)
		ray.target_position = Vector2(0, -rise_dist)
		ray.force_raycast_update()
		if ray.is_colliding():
			var hit_y = ray.get_collision_point().y
			if hit_y > closest_ceiling_y:
				closest_ceiling_y = hit_y
	# Snap to ceiling
	if closest_ceiling_y != -INF and parent.velocity.y < 0:
		parent.global_position.y = closest_ceiling_y + half_height
		parent.velocity.y = 0
	# Left wall
	var move_dist_x = parent.velocity.x * delta
	parent.SideL.target_position = Vector2(-abs(move_dist_x), 0)
	parent.SideL.force_raycast_update()
	if parent.SideL.is_colliding() and parent.velocity.x < 0:
		var hit_x = parent.SideL.get_collision_point().x
		parent.global_position.x = hit_x + half_width
		parent.velocity.x = 0
	# Right wall
	parent.SideR.target_position = Vector2(abs(move_dist_x), 0)
	parent.SideR.force_raycast_update()
	if parent.SideR.is_colliding() and parent.velocity.x > 0:
		var hit_x = parent.SideR.get_collision_point().x
		parent.global_position.x = hit_x - half_width
		parent.velocity.x = 0


func landing():
	# Only land from air and if falling
	if not state_includes([states.AIR, states.DAIR, states.UAIR, states.FAIR, states.BAIR, states.NAIR, states.AIR_DODGE, states.FREE_FALL, states.DOWN_SPECIAL]) or parent.velocity.y <= 0:
		return false
	# Initialize collision as none for predictive check
	var closest_hit_y := INF
	# Predictive snap check using rays
	for ray in [parent.GroundL, parent.GroundR]:
		# Estimate fall distance this frame
		var fall_dist := maxf(parent.velocity.y * get_physics_process_delta_time(), 8)
		ray.target_position = Vector2(0, fall_dist)
		if ray.is_colliding():
			var hit_y: float = ray.get_collision_point().y
			if hit_y < closest_hit_y:
				closest_hit_y = hit_y
	# If we found a collision, snap character
	if closest_hit_y != INF:
		if state_includes([states.AIR_DODGE, states.DOWN_SPECIAL]):
			parent.enable_hurtbox()
		#calculate snap location by platform location minus half sprite height
		parent.global_position.y = closest_hit_y - (parent.get_node("CollisionBox").shape).extents.y
		parent.velocity.y = 0
		parent.fastfall = false
		parent.reset_frame()
		return true
	return false


func falling():
	# Ensure everything is initialized first
	if not parent or not parent.GroundL or not parent.GroundR:
		return false
	# Detect falling (no jump press)
	if state_includes([states.STAND,states.DASH, states.RUN, states.CROUCH, states.JUMP_SQUAT, states.WALK, states.DASH_ATTACK, states.FORWARD_SMASH, states.ROLL_RIGHT, states.ROLL_LEFT]):
		if not parent.GroundL.is_colliding() and not parent.GroundR.is_colliding():
			parent.reset_hurtbox()
			parent.enable_hurtbox()
			return true


func ledge():
	if state_includes([states.AIR, states.AIR_DODGE, states.FREE_FALL, states.UP_SPECIAL_1, states.SIDE_SPECIAL_1, states.DOWN_SPECIAL]):
		for ray in [parent.LedgeGrabF, parent.LedgeGrabB]:
			if ray.is_colliding():
				var collider = ray.get_collider()
				#Ledge L
				if collider.get_node('Label').text == 'Ledge_L' and not Input.is_action_pressed("down_%s" % id) and parent.regrab == 0:
					parent.frame = 0
					parent.velocity.x = 0
					parent.velocity.y = 0
					self.parent.position.x = collider.position.x - 50
					self.parent.position.y = collider.position.y + 10
					parent.turn(false)
					parent.reset_jumps()
					parent.reset_air_dodge()
					parent.fastfall = false
					parent.last_ledge = collider
					return true
				#Ledge R
				if collider.get_node('Label').text == 'Ledge_R' and not Input.is_action_pressed("down_%s" % id) and parent.regrab == 0:
					parent.frame = 0
					parent.velocity.x = 0
					parent.velocity.y = 0
					self.parent.position.x = collider.position.x + 50
					self.parent.position.y = collider.position.y + 10
					parent.turn(true)
					parent.reset_jumps()
					parent.reset_air_dodge()
					parent.fastfall = false
					parent.last_ledge = collider
					return true
