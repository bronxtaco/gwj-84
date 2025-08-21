extends RigidBody2D

@export var gemType : Global.GemType = Global.GemType.Blue

@export var  dropSpawnTime : float = 0.5

@export var gemRepulseSpeed : float = 40

var gemDamage : int = 0

var useDropSpawn : bool = true

var spawnImpulse : Vector2

var initialCollisionLayers : int = 0
var initialCollisionMasks : int = 0

var removingGem : bool = false

var shader_nodes = []
var ultra_shader_param_offset: int = 0

func _ready():
	Events.attack_phase_begin.connect(_on_phase_change)
	Events.attack_phase_end.connect(_on_phase_change)
	Events.defence_phase_begin.connect(_on_phase_change)
	Events.defence_phase_end.connect(_on_phase_change)
	initialCollisionLayers = get_collision_layer()
	initialCollisionMasks = get_collision_mask()
	
	shader_nodes.push_back(%Sprite)
	shader_nodes.push_back($%DamageNumberLabel)

func set_gem_visuals(type: Global.GemType):
	# update visibily of the different sprites or text labels
	%MultiplyIcon.visible = type == Global.GemType.Multiply || type == Global.GemType.KillGem
	%DivideIcon.visible = type == Global.GemType.Divide
	%DamageNumberLabel.visible = !%MultiplyIcon.visible && !%DivideIcon.visible
	
	apply_gem_color(Global.get_gem_color(type))
	if !(gemType == Global.GemType.Ultra):
		for n in shader_nodes:
			n.material = null
	
	%DamageNumber.scale = Vector2(1.0, 1.0) # damage number will set the scale. Just put to default each time
	
	var isDamageNumber = type != Global.GemType.Multiply && type != Global.GemType.Divide
	if isDamageNumber:
		set_damage_number_text(gemDamage)
	
func set_damage_number_text(gemDamage: int):
	var gemDamageText = str(gemDamage)
	%DamageNumberLabel.text = gemDamageText
	
	# scale number as it gets longer. Only to a certain point. Let the game break if numbers get huge
	var scaleVal = 1.0
	match(len(gemDamageText)):
		1:
			scaleVal = 1.25
		2:
			scaleVal = 1.15
		3:
			scaleVal = 0.95
		4:
			scaleVal = 0.85
		5:
			scaleVal = 0.7
		6:
			scaleVal = 0.55
	%DamageNumber.scale = Vector2(scaleVal, scaleVal)

func apply_gem_color(color : Color):
	%Sprite.set_self_modulate(color)
	%DamageNumberLabel.set_self_modulate(color)
	%MultiplyIcon.set_self_modulate(color)
	%DivideIcon.set_self_modulate(color)
	%CollideParticle.color = color

func setup_gem(type: Global.GemType, gemPos: Vector2, spawnImpulse: Vector2, useDropSpawn: bool):
	global_position = gemPos # set the gem in the right spot, but offset the gem sprite in anim
	
	gemType = type
	refresh_gem_damage()
	
	self.useDropSpawn = useDropSpawn
	self.spawnImpulse = spawnImpulse
	
	if !useDropSpawn:
		apply_central_impulse(spawnImpulse)
		%CollideParticle.emitting = true # one shot, play/emmits once
	else: #drop spawn
		set_collision_layer.call_deferred(0)
		set_collision_mask.call_deferred(0)
		
		var initSpriteYPos = %Sprite.position.y
		var initShadowScale = $Shadow.scale
		%Sprite.position.y = -300
		$Shadow.scale = Vector2(0, 0)
		
		Audio.gem_drop_play()
		
		if is_inside_tree():
			var dropOnSpawnTween = get_tree().create_tween()
			dropOnSpawnTween.tween_property(%Sprite, "position:y", initSpriteYPos, dropSpawnTime)
			dropOnSpawnTween.parallel().tween_property(%Shadow, "scale", initShadowScale, dropSpawnTime)
			dropOnSpawnTween.tween_callback(on_tween_end)

func on_tween_end():
	if useDropSpawn: # not really required as callback will never happen, but just incase someone else calls this
		set_collision_layer.call_deferred(initialCollisionLayers)
		set_collision_mask.call_deferred(initialCollisionMasks)
		apply_central_impulse(spawnImpulse) # apply spawn impulse after the gem has landed

func _physics_process(delta: float) -> void:
	if removingGem: return
	
	if gemType == Global.GemType.Ultra:
		for n in shader_nodes:
			ultra_shader_param_offset = wrapi(ultra_shader_param_offset + 1, 0, 359)
			n.material.set_shader_parameter("offset", ultra_shader_param_offset)
	
	for otherBody in get_colliding_bodies():
		if removingGem: continue # if self is already removing, don't do anything
	
		if otherBody.is_in_group("Obstacle"):
			if linear_velocity.length() > 45:
				var obst = otherBody.get_parent()
				obst.apply_damage(1)
				if obst.health <= 0:
					obst.queue_free.call_deferred()
			
		var isRigidBody = otherBody is RigidBody2D
		if !isRigidBody: continue;
		var otherRigidBody = otherBody as RigidBody2D
		
		var isGem = "gemType" in otherRigidBody
		if !isGem: continue
		var otherGem = otherRigidBody
		gems_collided(otherGem)
	
	# Goal repulse area works in the opposite way. Use it to get the overlapping bodies and then apply for force to it
	for overlapBody in %RepulseArea.get_overlapping_bodies():
		if overlapBody == self: continue # skip ourselves
		
		var isRigidBody = overlapBody is RigidBody2D
		if !isRigidBody: continue 
		var rigidBody = overlapBody as RigidBody2D
		
		var isGem = "gemType" in rigidBody
		if !isGem: continue
		var otherGem = rigidBody

		var otherGemSpeed = otherGem.linear_velocity.length()
		if otherGemSpeed < gemRepulseSpeed:
			var speedToAdd = max( gemRepulseSpeed - otherGemSpeed, 0.0)
			var pushDirection = (otherGem.position - position ).normalized()
			otherGem.apply_force(pushDirection * speedToAdd)


func can_upgrade_on_collide(otherGem: RigidBody2D) -> bool:
	if gemType != otherGem.gemType:
		return false
	if gemType == Global.GemType.Ultra: # if already at max gem, early out
		return false
	if gemType == Global.GemType.Heal or otherGem.gemType == Global.GemType.Heal:
		return false # heal gems can't combine
	return true

func gems_collided(otherGem: RigidBody2D) -> void:
	# Here we know two gems collided.
	var canUpgrade = can_upgrade_on_collide(otherGem)

	if !canUpgrade:
		'''if linear_velocity.length() > 30:
			Audio.play_collide_sound() # only need to play 1 sound'''
		return
	
	print("combine called")
	
	var nextGemTypeIndex = min(gemType + 1, Global.GemType.size() - 1)
	var nextGemType = Global.GemType.values()[nextGemTypeIndex]
	var midPosition = (position + otherGem.position) * 0.5
	
	var spawnImpulse = calc_combined_gem_impulse(self, otherGem)
	
	Events.spawn_combined_gem_type.emit(nextGemType, midPosition, spawnImpulse, false)
	
	# set remove flags so the other doesn't also try combine collide
	removingGem = true
	otherGem.removingGem = true
	
	# dont think I need this anymore
	#set_collision_layer(0)
	#set_collision_mask(0)
	
	queue_free()
	otherGem.queue_free()
	
func calc_combined_gem_impulse(gemA: RigidBody2D, gemB: RigidBody2D) -> Vector2:
	# give the new gem some velocity. Combine both A and B and clamp within a sensible range.
	# if perfectly against each other, just use a 90 degree angle
	var minCombinedImpulseSpeed = 10
	var maxCombinedImpulseSpeed = 150
	
	var resultImpulse := Vector2()
	
	var velA = gemA.get_linear_velocity()
	var velB = gemB.get_linear_velocity()
	
	var speedASquared = velA.length_squared()
	var speedBSquared = velB.length_squared()
	
	var largerVel = velA if (speedASquared >= speedBSquared) else velB
	
	var hasMovingGems = speedASquared > 0 || speedBSquared > 0
	if !hasMovingGems: # if no movement somehow, just give random direction and min speed
		resultImpulse = minCombinedImpulseSpeed * gen_random_direction() 
	else:
		var combinedVelocity = velA + velB
		var combinedSpeedSqr = combinedVelocity.length_squared()
		if combinedSpeedSqr <= 0.0: # no velocity after coliding. Use the tangent
			var tangentDir = Vector2(-largerVel.y, largerVel.x).normalized()
			var impulseDir = tangentDir if (randi() % 2 == 0) else -tangentDir
			resultImpulse = minCombinedImpulseSpeed * impulseDir
		else:
			# clamp impulse speed
			var impulseSpeed = clamp(largerVel.length(), minCombinedImpulseSpeed, maxCombinedImpulseSpeed )
			resultImpulse = impulseSpeed * combinedVelocity.normalized()
	
	return resultImpulse

func gen_random_direction() -> Vector2:
	# my dumb way to get rid of zero length direction. But it works :D 
	var randDir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	while randDir.length_squared() == 0:
		randDir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	return randDir.normalized()


func refresh_gem_damage():
	if gemType == Global.GemType.KillGem:
		set_gem_visuals(gemType)
		return
	
	gemDamage = Global.get_gem_damage(gemType)
	if Global.attack_phase:
		if Global.active_relics[Global.Relics.GlassCannon]:
			gemDamage = max(ceil(gemDamage * 2), 1)
	elif Global.defence_phase:
		if Global.active_relics[Global.Relics.GlassCannon]:
			gemDamage = max(ceil(gemDamage / 2), 1)
	set_gem_visuals(gemType)


func _on_phase_change():
	refresh_gem_damage()
