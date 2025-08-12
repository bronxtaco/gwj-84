extends CharacterBody2D

@export var moveSpeed : float = 150.0
@export var chargingMoveSpeed : float = 40.0
@export var rollMoveSpeed : float = 300

@export var maxChargeTime : float = 2.0
@export var maxRollTime : float = 2.0

# turn speed number is somewhat ambiguous. If I hold left or right of the current roll direction,
# 	this value scales how much of that input is added to the roll direction
@export var rollTurnSpeed : float = 2.0 

enum State
{
	Idle = 0,
	Charging,
	Rolling
}
var state : State

var chargeTime : float = 0.0
var rollTime : float = 0.0

var currentRollDirection : Vector2
var lastInputDirection : Vector2

func _physics_process(delta):

	if state == State.Rolling:
		rollTime -= delta
		if rollTime <= 0:
			state = State.Idle
			%CritterSprite.play("walkLeftRight")
	elif state == State.Charging:
		chargeTime += delta;
		if chargeTime >= maxChargeTime || !Input.is_action_pressed("ballCharge"):
			# Start rolling if hit max charge or we let go of the input
			state = State.Rolling
			rollTime = 2.0
			currentRollDirection = lastInputDirection
	elif state == State.Idle:
		if Input.is_action_pressed("ballCharge"):
			# start charging
			state = State.Charging
			chargeTime = 0.0
			%CritterSprite.play("rollLeftRight")
	
	# read input always, so we can store the last input direction for the roll direction
	var inputDirection = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown");

	# free movement in idle
	if state == State.Idle:
		velocity = inputDirection * moveSpeed
		move_and_slide()
	elif state == State.Charging:
		velocity = inputDirection * chargingMoveSpeed
		move_and_slide()
	elif state == State.Rolling:
		# Add a small influence from input into the rolling.
		# isolate our inputDirection just into the lateral components, from the roll direction POV 
		var inputOntoRollDir = inputDirection.dot(currentRollDirection) * currentRollDirection
		var inputLateral = inputDirection - inputOntoRollDir
		
		currentRollDirection += ( inputLateral * rollTurnSpeed * delta )
		currentRollDirection = currentRollDirection.normalized()
		
		var rollDelta = currentRollDirection * rollMoveSpeed * delta;
		
		var collision : KinematicCollision2D = move_and_collide(rollDelta)
		
		if collision:
			var otherCollider = collision.get_collider()
			if otherCollider is RigidBody2D:
				var impulseSpeed = rollMoveSpeed * 1.1
				otherCollider.apply_central_impulse(-collision.get_normal() * impulseSpeed)
				print("critter hit gem")
			rollTime = 0.0 # stop rolling every time you collide
	
	
	# if we have any velocity, update are sprite direction and anim based of it
	var hasVelocity = velocity.length_squared() > 0.0
	if hasVelocity:
		var nextAnim = %CritterSprite.animation
		
		var useXAsDirection = abs(velocity.x) >= abs(velocity.y)
		if useXAsDirection: # x is larger, so use left and right anims
			$CritterSprite.scale.x = sign(velocity.x) * abs($CritterSprite.scale.x) # Flip the scale to invert
			if state == State.Idle:
				nextAnim = "walkLeftRight"
			elif state == State.Rolling || state == State.Charging:
				nextAnim = "rollLeftRight"
			
		else: # else Y velocity is larger. Use up and down anim directions
			$CritterSprite.scale.x = abs($CritterSprite.scale.x) # reset to normal x scale
			
			if sign(velocity.y) >= 0:
				if state == State.Idle:
					nextAnim = "walkDown"
				elif state == State.Rolling || state == State.Charging:
					nextAnim = "rollDown"
			else:
				if state == State.Idle:
					nextAnim = "walkUp"
				elif state == State.Rolling || state == State.Charging:
					nextAnim = "rollUp"
		
		$CritterSprite.play(nextAnim)
		
	else: # we have no velocity. Pause anim if in idle
		if state == State.Idle:
			%CritterSprite.pause()
	
	# store the last input direction that isn't zero. Used for roll direction if no input is exists
	if inputDirection.length_squared() > 0:
		lastInputDirection = inputDirection
