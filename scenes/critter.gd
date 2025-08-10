extends CharacterBody2D

enum State
{
	Idle = 0,
	Charging,
	Rolling
}
var state : State

var chargeTime : float = 0.0
var maxChargeTime : float = 2.0
var chargeTimeToRollSpeedRatio : float = 10.0 # holding charge longer increases the speed by this multiplier

var rollSpeed : float = 200
var rollTime : float
var rollDirection : Vector2

var lastInputDirection : Vector2


func _physics_process(delta):

	if state == State.Rolling:
		rollTime -= delta
		if rollTime <= 0:
			state = State.Idle
			%CritterSprite.play("default")
	elif state == State.Charging:
		chargeTime += delta;
		if chargeTime >= maxChargeTime || !Input.is_action_pressed("ballCharge"):
			# Start rolling if hit max charge or we let go of the input
			state = State.Rolling
			# rollSpeed = chargeTime * chargeTimeToRollSpeedRatio # TODO: not sure if I need this. do we want varying roll speeds?
			rollTime = 2.0
			rollDirection = lastInputDirection
			%CritterSprite.play("roll")
	elif state == State.Idle:
		if Input.is_action_pressed("ballCharge"):
			# start charging
			state = State.Charging
			chargeTime = 0.0
			%CritterSprite.play("charge")
	
	# read input always, so we can store the last input direction for the roll direction
	var inputDirection : Vector2;
	if Input.is_action_pressed("moveLeft"):
		inputDirection.x -= 1.0
	elif Input.is_action_pressed("moveRight"):
		inputDirection.x += 1.0
		
	if Input.is_action_pressed("moveUp"):
		inputDirection.y -= 1.0
	elif Input.is_action_pressed("moveDown"):
		inputDirection.y += 1.0

	inputDirection = inputDirection.normalized()
	
	# free movement in idle
	if state == State.Idle:
		var moveSpeed = 200.0
		var moveDelta = inputDirection * moveSpeed * delta;
		move_and_collide(moveDelta)
	elif state == State.Rolling:
		# Add a small influence from input into the rolling.
		# isolate our inputDirection just into the lateral components, from the roll direction POV 
		var inputOntoRollDir = inputDirection.dot(rollDirection) * rollDirection
		var inputLateral = inputDirection - inputOntoRollDir
		
		var lateralInfluence = 2.0
		rollDirection += ( inputLateral * lateralInfluence * delta )
		rollDirection = rollDirection.normalized()
		
		var rollVelocity = rollDirection * rollSpeed * delta;
		var collision : KinematicCollision2D = move_and_collide(rollVelocity)
		if collision:
			var otherCollider = collision.get_collider()
			if otherCollider is RigidBody2D:
				var impulseSpeed = rollSpeed * 1.1
				otherCollider.apply_central_impulse(-collision.get_normal() * impulseSpeed)
				print("critter hit gem")
			rollTime = 0.0 # stop rolling every time you collide
	
	lastInputDirection = inputDirection
