extends CharacterBody2D

@export var attract_mode := false

@export var sprintSpeed : float = 250
@export var walkSpeed : float = 150.0 # default move speed

@export var chargeBackSpeed : float = 80

@export var attackMinMoveSpeed : float = 150 # attack min speed when not charged
@export var attackMaxMoveSpeed : float = 500 # fastest attack speed when fully charged

@export var minAttackTime : float = 0.08 # how long is the attack forward motion 
@export var maxAttackTime : float = 0.65 # how long is the attack forward motion 

@export var maxChargeTime : float = 1.5 # how long attack charge up can be held

@export var aimLineMinLength : float = 10
@export var aimLineMaxLength : float = 23

const RelicMoveSpeedMultiplier := 1.5

enum State
{
	Idle = 0,
	Charging,
	Attack,
	Walk
}
var state : State

var chargeTime : float = 0.0
var attackTimeRemaining : float = maxAttackTime

var attackMoveSpeed : float = attackMaxMoveSpeed # calculated by the amount of time attack is charged

var rollDirection : Vector2 # used by the roll/sprint. Travels in this direction and updates with sidewards input
var lastFaceDirection := Vector2(1.0, 0.0)
var lastAimVector := Vector2(0.0, 0.0) # not normalized

var minInputToAim = 0.2
var minInputToAimSqr = minInputToAim * minInputToAim

var wasChargeHeld : bool = false

func _ready() -> void:
	if attract_mode:
		%AttractMoveTimer.start()
	%ChargingSprite.visible = false
	%ChargingSprite.play()

func _physics_process(delta):
	
	var walkInputHeld = false
	var chargeInputHeld = false
	if attract_mode:
		if $AttractWaitTimer.is_stopped() and state == State.Idle:
			chargeInputHeld = true
			var target_gem = get_parent().get_random_gem()
			if target_gem:
				$AttractMoveTimer.start()
				lastAimVector = global_position.direction_to(target_gem.global_position)
		elif state == State.Charging:
			chargeInputHeld = !$AttractMoveTimer.is_stopped()
		elif $AttractWaitTimer.is_stopped() and state == State.Attack:
			$AttractWaitTimer.start()
	else:
		walkInputHeld = Input.is_action_pressed("walk")
		chargeInputHeld = Input.is_action_pressed("ballCharge")
	
	var play_scuttle_sound := false
	if state == State.Walk:
		if !walkInputHeld:
			state = State.Idle
	elif state == State.Charging:
		chargeTime += delta;
		if chargeTime >= maxChargeTime || !chargeInputHeld:
			state = State.Attack
			
			rollDirection = lastAimVector.normalized() if lastAimVector.length_squared() >= minInputToAimSqr else rollDirection
			attackMoveSpeed = remap(chargeTime, 0, maxChargeTime, attackMinMoveSpeed, attackMaxMoveSpeed) 
			attackTimeRemaining = remap(chargeTime, 0, maxChargeTime, minAttackTime, maxAttackTime )
			%ChargingSprite.visible = false
			%AimingLine.visible = false
	elif state == State.Attack:
		attackTimeRemaining -= delta;
		if attackTimeRemaining <= 0:
			state = State.Idle
			%CritterSprite.play("walkLeftRight")
	elif state == State.Idle:
		if chargeInputHeld && !wasChargeHeld:
			# start charging
			%ChargeSound.play()
			state = State.Charging
			rollDirection = lastFaceDirection
			chargeTime = 0
			%ChargingSprite.visible = true
			%CritterSprite.play("rollLeftRight")
		elif walkInputHeld:
			state = State.Walk
	
	wasChargeHeld = chargeInputHeld
	
	# read input always, so we can store the last input direction for the roll direction
	var inputDirection = Vector2.ZERO if attract_mode else Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	var move_multiplier = RelicMoveSpeedMultiplier if Global.active_relics[Global.Relics.MoveSpeed] else 1.0
	
	if inputDirection.length_squared() >= minInputToAimSqr:
		lastAimVector = inputDirection
	
	const PushGemForce = 0.7
	var pushGemForceRelicActive = Global.active_relics[Global.Relics.PushGemNoCharge]
	# free movement in idle
	if state == State.Idle:
		velocity = inputDirection * (sprintSpeed * move_multiplier)
		move_and_slide()
		if pushGemForceRelicActive:
			apply_gem_collisions(PushGemForce)
	elif state == State.Walk:
		velocity = inputDirection * (walkSpeed * move_multiplier)
		move_and_slide()
		if pushGemForceRelicActive:
			apply_gem_collisions(PushGemForce)
	elif state == State.Charging:
		pass
	elif state == State.Attack:
		velocity = rollDirection * (attackMoveSpeed * move_multiplier)
		move_and_slide()
		if apply_gem_collisions(1.1):
			$GemImpactSound.play()
			attackTimeRemaining = 0.0 # stop rolling every time you collide with anything
			
	# if we have any velocity, update are sprite direction and anim based of it
	var hasVelocity = velocity.length_squared() > 0.0
	if hasVelocity:
		var nextAnim = %CritterSprite.animation
		
		var useXAsDirection = abs(velocity.x) >= abs(velocity.y)
		if useXAsDirection: # x is larger, so use left and right anims
			$CritterSprite.scale.x = sign(velocity.x) * abs($CritterSprite.scale.x) # Flip the scale to invert
			if state == State.Idle || state == State.Walk:
				nextAnim = "walkLeftRight"
			elif state == State.Charging:
				nextAnim = "rollLeftRight"
			
		else: # else Y velocity is larger. Use up and down anim directions
			$CritterSprite.scale.x = abs($CritterSprite.scale.x) # reset to normal x scale
			
			if sign(velocity.y) >= 0:
				if state == State.Idle || state == State.Walk:
					nextAnim = "walkDown"
				elif state == State.Charging:
					nextAnim = "rollDown"
			else:
				if state == State.Idle || state == State.Walk:
					nextAnim = "walkUp"
				elif state == State.Charging:
					nextAnim = "rollUp"
		
		if state == State.Idle || state == State.Walk:
			play_scuttle_sound = true
		
		$CritterSprite.play(nextAnim)
		
		# store the last input direction that isn't zero. Used for roll direction if no input is exists
		lastFaceDirection = velocity.normalized()
		
	else: # we have no velocity. Pause anim if in idle
		if state == State.Idle || state == State.Walk:
			%CritterSprite.pause()
	
	if play_scuttle_sound:
		if !$ScuttleSound.playing:
			print("ScuttleSound: Play")
			$ScuttleSound.play()
	else:
		if $ScuttleSound.playing:
			print("ScuttleSound: Stop")
			$ScuttleSound.stop()


func apply_gem_collisions(force_mult: float) -> bool:
	var collision : KinematicCollision2D = get_last_slide_collision()
	if velocity == Vector2.ZERO:
		return false
	
	if collision:
		var otherCollider = collision.get_collider()
		var isRigidBody = otherCollider is RigidBody2D
		if isRigidBody:  
			var otherRigidBody = otherCollider as RigidBody2D
			var isGem = "gemType" in otherRigidBody
			if isGem: 
				var impulseSpeed = abs(velocity) * force_mult #attackMoveSpeed * 1.1
				otherCollider.apply_central_impulse(-collision.get_normal() * impulseSpeed)
				print("velocity %.2f %.2f" % [velocity.x, velocity.y])
				print("impulseSpeed %.2f %.2f" % [impulseSpeed.x, impulseSpeed.y])
				print("-collision.get_normal() * impulseSpeed %.2f %.2f" % [(-collision.get_normal() * impulseSpeed).x, (-collision.get_normal() * impulseSpeed).y])
				return true
	return false


func get_lateral_input(inputDirection: Vector2, moveDirection: Vector2) -> Vector2:
	# isolate our inputDirection just into the lateral components, from the roll direction POV 
	var inputOntoRollDir = inputDirection.dot(moveDirection) * moveDirection
	var inputLateral = inputDirection - inputOntoRollDir
	return inputLateral


const attract_walk_time := 2.0
var attract_prev_pos: Vector2 = Vector2.ZERO
func _on_attract_move_timer_timeout() -> void:
	if !attract_mode:
		return
	
	'''var critter_locations = get_parent().get_attract_locations()
	%AttractMoveTimer.wait_time = attract_walk_time + randf_range(0.5, 1.5)
	var i = randi() % critter_locations.get_child_count()
	var target_pos = critter_locations.get_child(i)
	var x_diff = target_pos.global_position.x - attract_prev_pos.x
	var y_diff = target_pos.global_position.y - attract_prev_pos.y
	if abs(x_diff) > abs(y_diff):
		%CritterSprite.play("walkLeftRight")
		%CritterSprite.flip_h = x_diff < 0
	else:
		if y_diff > 0:
			%CritterSprite.play("walkDown")
		else:
			%CritterSprite.play("walkUp")
	attract_prev_pos = target_pos.global_position
	var tween = create_tween().tween_property(%CritterSprite, "global_position", target_pos.global_position, attract_walk_time)
	await tween.finished
	%CritterSprite.stop()'''
