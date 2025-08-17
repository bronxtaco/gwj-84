extends Area2D

@export var repulseSpeed : float = 35

func _physics_process(delta: float) -> void:
	# Goal repulse area works in the opposite way. Use it to get the overlapping bodies and then apply for force to it
	for overlapBody in %GoalRepulseArea.get_overlapping_bodies():
		var isRigidBody = overlapBody is RigidBody2D
		if !isRigidBody: continue 
		var rigidBody = overlapBody as RigidBody2D
		
		var isGem = "gemType" in rigidBody
		if !isGem: continue
		var gem = rigidBody

		
		var gemSpeed = gem.linear_velocity.length()
		if gemSpeed < repulseSpeed:
			var speedToAdd = max( repulseSpeed - gemSpeed, 0.0)
			var pushDirection = (gem.position - %GoalRepulseArea.position ).normalized()
			gem.apply_force(pushDirection * speedToAdd)

func _on_body_entered(body: Node2D) -> void:
	var isRigidBody = body is RigidBody2D
	if !isRigidBody: return 
	
	var rigidBody = body as RigidBody2D
	var isGem = "gemType" in rigidBody
	if !isGem: return
	var gem = rigidBody
	
	%SuccessAudio.play()
	if gem.gemType == Global.GemType.Heal:
		Events.heal_boost.emit(gem.gemDamage)
	else:
		Events.crit_boost.emit(gem.gemType, gem.gemDamage)
	gem.queue_free()
