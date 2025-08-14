extends CharacterBody2D

@export var moveSpeed : float = 150.0 # default move speed
@export var sprintSpeed : float = 250

@export var attackMinMoveSpeed : float = 150 # attack min speed when not charged
@export var attackMaxMoveSpeed : float = 500 # fastest attack speed when fully charged

@export var minAttackTime : float = 0.08 # how long is the attack forward motion 
@export var maxAttackTime : float = 0.35 # how long is the attack forward motion 

@export var maxChargeTime : float = 1.5 # how long attack charge up can be held

# turn speed number is somewhat ambiguous. If I hold left or right of the current roll direction,
# 	this value scales how much of that input is added to the roll direction
@export var rollTurnSpeed : float = 2.5 

@export var aimLineMinLength : float = 20
@export var aimLineMaxLength : float = 60

enum State
{
	Idle = 0,
	Charging,
	Attack,
	Sprint,
	Rolling # not in use
}
var state : State

var chargeTime : float = 0.0
var attackTimeRemaining : float = maxAttackTime

var attackMoveSpeed : float = attackMaxMoveSpeed # calculated by the amount of time attack is charged

var rollDirection : Vector2 # used by the roll/sprint. Travels in this direction and updates with sidewards input
var lastFaceDirection := Vector2(1.0, 0.0)

func _ready() -> void:
	%ChargingSprite.visible = false
	%ChargingSprite.play()

func _physics_process(delta):
	
	var sprintInputHeld = Input.is_action_pressed("sprint")
	
	var play_scuttle_sound := false
	if state == State.Sprint:
		if !sprintInputHeld:
			state = State.Idle
	elif state == State.Charging:
		chargeTime += delta;
		if chargeTime >= maxChargeTime || !Input.is_action_pressed("ballCharge"):
			state = State.Attack
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
		if Input.is_action_pressed("ballCharge"):
			# start charging
			state = State.Charging
			rollDirection = lastFaceDirection
			chargeTime = 0
			%ChargingSprite.visible = true
			%CritterSprite.play("rollLeftRight")
		elif sprintInputHeld:
			state = State.Sprint
			#%CritterSprite.play("rollLeftRight")
	
	# update aiming particles
	if state == State.Charging:
		#%AimingLine.visible = true # TODO Disabled for now, not sure about it
		
		var lineLength = remap(chargeTime, 0, maxChargeTime, aimLineMinLength, aimLineMaxLength )
		%AimingLine.points[1] = rollDirection * lineLength

	
	# read input always, so we can store the last input direction for the roll direction
	var inputDirection = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown");

	# free movement in idle
	if state == State.Idle:
		velocity = inputDirection * moveSpeed
		move_and_slide()
	elif state == State.Sprint:
		velocity = inputDirection * sprintSpeed
		move_and_slide()
	if state == State.Rolling: # not in use
		# Add a small influence from input into the rolling.
		var inputLateral = get_lateral_input(inputDirection, rollDirection)
		rollDirection += ( inputLateral * rollTurnSpeed * delta )
		rollDirection = rollDirection.normalized()
		
		var rollMoveSpeed = sprintSpeed
		velocity = rollDirection * rollMoveSpeed
		move_and_slide()
	elif state == State.Charging:
		
		var inputLateral = get_lateral_input(inputDirection, rollDirection)
		rollDirection += ( inputLateral * rollTurnSpeed * delta )
		rollDirection = rollDirection.normalized()
		
		var attackMoveDelta = -rollDirection * 20 * delta;
		
		var collision : KinematicCollision2D = move_and_collide(attackMoveDelta)

		

	elif state == State.Attack:
		var attackMoveDelta = rollDirection * attackMoveSpeed * delta;
		
		var collision : KinematicCollision2D = move_and_collide(attackMoveDelta)
		
		if collision:
			var otherCollider = collision.get_collider()
			if otherCollider is RigidBody2D:
				var impulseSpeed = attackMoveSpeed * 1.1
				otherCollider.apply_central_impulse(-collision.get_normal() * impulseSpeed)
				$GemImpactSound.play()
				print("critter hit gem")
			attackTimeRemaining = 0.0 # stop rolling every time you collide
	
	
	# if we have any velocity, update are sprite direction and anim based of it
	var hasVelocity = velocity.length_squared() > 0.0
	if hasVelocity:
		var nextAnim = %CritterSprite.animation
		
		var useXAsDirection = abs(velocity.x) >= abs(velocity.y)
		if useXAsDirection: # x is larger, so use left and right anims
			$CritterSprite.scale.x = sign(velocity.x) * abs($CritterSprite.scale.x) # Flip the scale to invert
			if state == State.Idle || state == State.Sprint:
				nextAnim = "walkLeftRight"
			elif state == State.Rolling || state == State.Charging:
				nextAnim = "rollLeftRight"
			
		else: # else Y velocity is larger. Use up and down anim directions
			$CritterSprite.scale.x = abs($CritterSprite.scale.x) # reset to normal x scale
			
			if sign(velocity.y) >= 0:
				if state == State.Idle || state == State.Sprint:
					nextAnim = "walkDown"
				elif state == State.Rolling || state == State.Charging:
					nextAnim = "rollDown"
			else:
				if state == State.Idle || state == State.Sprint:
					nextAnim = "walkUp"
				elif state == State.Rolling || state == State.Charging:
					nextAnim = "rollUp"
		
		if state == State.Idle || state == State.Sprint:
			play_scuttle_sound = true
		
		$CritterSprite.play(nextAnim)
		
		# store the last input direction that isn't zero. Used for roll direction if no input is exists
		lastFaceDirection = velocity.normalized()
		
	else: # we have no velocity. Pause anim if in idle
		if state == State.Idle || state == State.Sprint:
			%CritterSprite.pause()
	
	if play_scuttle_sound:
		if !$ScuttleSound.playing:
			print("ScuttleSound: Play")
			$ScuttleSound.play()
	else:
		if $ScuttleSound.playing:
			print("ScuttleSound: Stop")
			$ScuttleSound.stop()

func get_lateral_input(inputDirection: Vector2, moveDirection: Vector2) -> Vector2:
	# isolate our inputDirection just into the lateral components, from the roll direction POV 
	var inputOntoRollDir = inputDirection.dot(moveDirection) * moveDirection
	var inputLateral = inputDirection - inputOntoRollDir
	return inputLateral
