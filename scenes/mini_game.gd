extends Node2D

@export var gemScene: PackedScene

@export var maxSpawnedGems : int = 8
@export var gemSpawnTimeInterval : float = 3.0

@export var gemSpawnMinBounds := Vector2(0.0, 0.0)
@export var gemSpawnMaxBounds := Vector2(800, 600.0)

@export var goalExclusionRadius : float = 35.0

@export var arenaSideCenteringSpeed : float = 20 # speed applied when gem are outside the center polygon

var gemSpawnTimer = gemSpawnTimeInterval

func _ready() -> void:
	Events.fireball_exploded.connect(_on_fireball_exploded)
	Events.gems_collided.connect(_on_gems_collided)

func _process(delta: float) -> void:
	gemSpawnTimer -= delta
	
	if gemSpawnTimer <= 0.0:
		gemSpawnTimer = gemSpawnTimeInterval
		
		var gemCount = get_gem_count()
		if gemCount < maxSpawnedGems:
			var spawnCount = min(randi_range(1, 3), maxSpawnedGems - gemCount)
			for i in range(spawnCount):
				spawn_gem()

func _physics_process(delta: float) -> void:
	# loop over all gems and if they are outside the arena center polygon, nudge them back inside
	for gemNode in %SpawnedGems.get_children():
		var gem = gemNode as RigidBody2D
		var inCenter = Geometry2D.is_point_in_polygon(gem.position - %ArenaCenterPolygon.position, %ArenaCenterPolygon.polygon)
		if !inCenter:
			var toCenterDir = (%ArenaCenter.position - gem.position).normalized()
			var force = toCenterDir * arenaSideCenteringSpeed
			gem.apply_force(force)

func get_gem_count():
	return %SpawnedGems.get_child_count()

func clear_gems():
	for gem in %SpawnedGems.get_children():
		gem.queue_free()

func spawn_gem_type(gemType: Global.GemType, position: Vector2, impulse: Vector2, useDropSpawn: bool):
	var gem = gemScene.instantiate() as Node2D
	%SpawnedGems.add_child(gem)
	gem.setup_gem(gemType, position, impulse, useDropSpawn)

func is_spawn_pos_empty(pos: Vector2, radius: float) -> bool:
	# TODO: Get gem scene for radius? Shape doesn't exist yet so that isn't an option unless we used a dummy
	var shape_rid = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(shape_rid, radius)

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape_rid = shape_rid
	params.transform.origin = pos
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.margin = 0

	var space_state = get_world_2d().direct_space_state
	var intersectResult = space_state.intersect_shape(params, 4)
	
	PhysicsServer2D.free_rid(shape_rid) # Release the shape when done with physics queries.
	
	var isEmptyPos = intersectResult.size() == 0
	return isEmptyPos

func spawn_gem():
	# find point to spawn gem
	var spawnPos : Vector2
	var foundPos = false
	
	var maxPosSearches = 64 #
	while maxPosSearches > 0:
		maxPosSearches -= 1
		
		var posX = randf_range(gemSpawnMinBounds.x, gemSpawnMaxBounds.x)
		var posY = randf_range(gemSpawnMinBounds.y, gemSpawnMaxBounds.y)
		var randomPoint = Vector2(posX, posY)
		
		var inArena = Geometry2D.is_point_in_polygon(randomPoint - %ArenaPolygon.position, %ArenaPolygon.polygon)
		var inGoal = Geometry2D.is_point_in_circle(randomPoint, %Goal.position, goalExclusionRadius)	
		if inArena && !inGoal:
			var gemRadius = 15 # TODO: is there a way to get this direction for un-instantiated scene?
			if is_spawn_pos_empty(randomPoint, gemRadius):
				spawnPos = randomPoint
				break # break out of while loop, as we found a pos
	
	var dropSpawnImpulseAmount : float = 9.0
	var spawnImpulse = dropSpawnImpulseAmount * gen_random_direction()
	
	# random gem type
	var gemType = Global.GemType.Blue
	spawn_gem_type(gemType, spawnPos, spawnImpulse, true)

func _on_goal_body_entered(body: Node2D) -> void:
	var isRigidBody = body is RigidBody2D
	if !isRigidBody: return 
	
	var rigidBody = body as RigidBody2D
	var isGem = "gemType" in rigidBody
	if !isGem: return
	
	var gem = rigidBody
	%SuccessAudio.play()
	Events.crit_boost.emit(gem.gemType, gem.gemDamage)
	gem.queue_free()

func _on_fireball_exploded():
	clear_gems()

func _on_gems_collided(initialGemType: Global.GemType, gemA: RigidBody2D, gemB: RigidBody2D):
	var no_upgrade = false
	if gemA.gemType != gemB.gemType:
		no_upgrade = true # if are not the same type, then do not upgrade there color
	
	var gemType = gemA.gemType
	
	if initialGemType != gemType:
		# if gem type is different then initial type. Then we have likely already handled these two gems colliding this frame
		no_upgrade = true
	
	if gemType == Global.GemType.Red: # if already at max gem, early out
		no_upgrade = true
	
	if no_upgrade:
		gemA.play_collide_sound() # only need to play 1 sound
		return
	
	gemA.play_upgrade_sound() # only need to play 1 sound
	
	var nextGemTypeIndex = min(gemType + 1, Global.GemType.size() - 1)
	var nextGemType = Global.GemType.values()[nextGemTypeIndex]
	var midPosition = (gemA.position + gemB.position) * 0.5
	
	var spawnImpulse = calc_combined_gem_impulse(gemA, gemB)
	
	spawn_gem_type(nextGemType, midPosition, spawnImpulse, false)
	
	gemA.remove_gem()
	gemB.remove_gem()
	

func gen_random_direction() -> Vector2:
	# my dumb way to get rid of zero length direction. But it works :D 
	var randDir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	while randDir.length_squared() == 0:
		randDir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	return randDir.normalized()

func calc_combined_gem_impulse(gemA: RigidBody2D, gemB: RigidBody2D) -> Vector2:
	# give the new gem some velocity. Combine both A and B and clamp within a sensible range.
	# if perfectly against each other, just use a 90 degree angle
	var minCombinedImpulseSpeed = 10
	var maxCombinedImpulseSpeed = 40
	
	var resultImpulse := Vector2()
	
	var velA = gemA.get_linear_velocity()
	var velB = gemB.get_linear_velocity()
	
	var speedASquared = velA.length_squared()
	var speedBSquared = velB.length_squared()
	
	var hasMovingGems = speedASquared > 0 || speedBSquared > 0
	if !hasMovingGems: # if no movement somehow, just give random direction and min speed
		resultImpulse = minCombinedImpulseSpeed * gen_random_direction() 
	else:
		var combinedVelocity = velA + velB
		var combinedSpeed = combinedVelocity.length_squared()
		if combinedSpeed <= 0.0: # no velocity after coliding. Use the tangent
			var largerVel = velA if (speedASquared >= speedBSquared) else velB
			var tangentDir = Vector2(-largerVel.y, largerVel.x).normalized()
			var impulseDir = tangentDir if (randi() % 2 == 0) else -tangentDir
			resultImpulse = minCombinedImpulseSpeed * impulseDir
		else:
			# clamp impulse speed
			var impulseSpeed = clamp(combinedSpeed, minCombinedImpulseSpeed, maxCombinedImpulseSpeed )
			resultImpulse = impulseSpeed * combinedVelocity.normalized()
	
	return resultImpulse
