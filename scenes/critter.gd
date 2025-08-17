extends CharacterBody2D

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
	%ChargingSprite.visible = false
	%ChargingSprite.play()

func _physics_process(delta):
	
	var walkInputHeld = Input.is_action_pressed("walk")
	var chargeInputHeld = Input.is_action_pressed("ballCharge")
	
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
	var inputDirection = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	var move_multiplier = RelicMoveSpeedMultiplier if Global.active_relics[Global.Relics.MoveSpeed] else 1.0
	
	if inputDirection.length_squared() >= minInputToAimSqr:
		lastAimVector = inputDirection
	
	# free movement in idle
	if state == State.Idle:
		velocity = inputDirection * (sprintSpeed * move_multiplier)
		move_and_slide()
	elif state == State.Walk:
		velocity = inputDirection * (walkSpeed * move_multiplier)
		move_and_slide()
	elif state == State.Charging:
		pass
	elif state == State.Attack:
		velocity = rollDirection * (attackMoveSpeed * move_multiplier)
		move_and_slide()
		
		var collision : KinematicCollision2D = get_last_slide_collision()
		if collision:
			var otherCollider = collision.get_collider()
			var isRigidBody = otherCollider is RigidBody2D
			if isRigidBody:  
				var otherRigidBody = otherCollider as RigidBody2D
				var isGem = "gemType" in otherRigidBody
				if isGem: 
					var impulseSpeed = attackMoveSpeed * 1.1
					otherCollider.apply_central_impulse(-collision.get_normal() * impulseSpeed)
					$GemImpactSound.play()
				
				attackTimeRemaining = 0.0 # stop rolling every time you collide with a rigid body
			
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

func get_lateral_input(inputDirection: Vector2, moveDirection: Vector2) -> Vector2:
	# isolate our inputDirection just into the lateral components, from the roll direction POV 
	var inputOntoRollDir = inputDirection.dot(moveDirection) * moveDirection
	var inputLateral = inputDirection - inputOntoRollDir
	return inputLateral
