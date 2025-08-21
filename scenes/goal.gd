extends Area2D

@export var attractSpeed : float = 70
@export var repulseSpeed : float = 35

func _physics_process(delta: float) -> void:
	if Global.active_relics[Global.Relics.GoalAttractGems]:
		for overlapBody in %GoalAttractArea.get_overlapping_bodies():
			var isRigidBody = overlapBody is RigidBody2D
			if !isRigidBody: continue 
			var rigidBody = overlapBody as RigidBody2D
			
			var isGem = "gemType" in rigidBody
			if !isGem: continue
			
			var gem = rigidBody
			var gemSpeed = gem.linear_velocity.length()
			if gemSpeed < attractSpeed:
				var speedToAdd = max(attractSpeed - gemSpeed, 0.0)
				var pushDirection = (%GoalRepulseArea.global_position - gem.global_position).normalized()
				Events.draw_debug_vector_arrow.emit(gem.global_position, pushDirection * speedToAdd)
				gem.apply_force(pushDirection * speedToAdd)
	else:
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
				var speedToAdd = max(repulseSpeed - gemSpeed, 0.0)
				var pushDirection = (gem.global_position - %GoalRepulseArea.global_position).normalized()
				Events.draw_debug_vector_arrow.emit(gem.global_position, pushDirection * speedToAdd, Color.BLUE_VIOLET)
				gem.apply_force(pushDirection * speedToAdd)

func activate():
	visible = true
	monitoring = true
	monitorable = true

func deactivate():
	visible = false
	monitoring = false
	monitorable = false


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
	elif gem.gemType == Global.GemType.KillGem:	
		Events.kill_gem_scored.emit()
	else:
		Events.crit_boost.emit(gem.gemType, gem.gemDamage)
	gem.queue_free()
