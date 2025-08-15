extends Node2D

@export var gemScene: PackedScene

@export var maxSpawnedGems : int = 8
@export var gemSpawnTimeInterval : float = 3.0

@export var gemSpawnMinBounds := Vector2(0.0, 0.0)
@export var gemSpawnMaxBounds := Vector2(800, 600.0)

@export var goalExclusionRadius : float = 35.0

var gemSpawnTimer = gemSpawnTimeInterval

func _ready() -> void:
	Events.fireball_exploded.connect(_on_fireball_exploded)
	Events.gems_collided.connect(_on_gems_collided)

func _process(delta: float) -> void:
	gemSpawnTimer -= delta
	
	if gemSpawnTimer <= 0.0:
		gemSpawnTimer = gemSpawnTimeInterval
		if get_gem_count() < maxSpawnedGems:
			var spawnCount = randi_range(1, 3)
			for i in range(spawnCount):
				spawn_gem()

func _physics_process(delta: float) -> void:
	# loop over all gems and if they are outside the arena center polygon, nudge them back inside
	for gemNode in %SpawnedGems.get_children():
		var gem = gemNode as RigidBody2D
		var inCenter = Geometry2D.is_point_in_polygon(gem.position - %ArenaCenterPolygon.position, %ArenaCenterPolygon.polygon)
		if !inCenter:
			var toCenterDir = (%ArenaCenter.position - gem.position).normalized()
			
			var centeringSpeed = 15
			var force = toCenterDir * centeringSpeed
			gem.apply_force(force)
			

func get_gem_count():
	return %SpawnedGems.get_child_count()

func clear_gems():
	for gem in %SpawnedGems.get_children():
		gem.queue_free()

func spawn_gem_type(gemType: Global.GemType, position: Vector2):
	var gem = gemScene.instantiate() as Node2D
	%SpawnedGems.add_child(gem)
	gem.setup_gem(gemType, position)

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
	
	# random gem type
	var gemType = Global.GemType.Red if (randi() % 2 == 0) else Global.GemType.Blue

	spawn_gem_type(gemType, spawnPos)

func _on_goal_body_entered(body: Node2D) -> void:
	var isRigidBody = body is RigidBody2D
	if !isRigidBody: return 
	
	var rigidBody = body as RigidBody2D
	var isGem = "gemType" in rigidBody
	if !isGem: return
	
	var gem = rigidBody
	Events.crit_boost.emit(gem.gemType, gem.gemDamage)
	gem.queue_free()

func _on_fireball_exploded():
	clear_gems()

func _on_gems_collided(initialGemType: Global.GemType, gemA: RigidBody2D, gemB: RigidBody2D):
	if gemA.gemType != gemB.gemType:
		return # if are not the same type, then do not upgrade there color
	
	var gemType = gemA.gemType
	
	if initialGemType != gemType:
		# if gem type is different then initial type. Then we have likely already handled these two gems colliding this frame
		return 
	
	if gemType == Global.GemType.Gold: # if already at max gem, early out
		return
	
	# combining two of the same color generates two seperate colors
	var nextGemA = gemType
	var nextGemB = gemType
	
	var useNormalOrder = randi() % 2 == 0
	
	match(gemType):
		Global.GemType.Red, Global.GemType.Blue:
			nextGemA = Global.GemType.Green if useNormalOrder else Global.GemType.Orange
			nextGemB = Global.GemType.Orange if useNormalOrder else Global.GemType.Green
		Global.GemType.Orange, Global.GemType.Green: # secondary colors all become gold
			nextGemA = Global.GemType.Gold
			nextGemB = Global.GemType.Gold
	
	gemA.setup_gem_type(nextGemA)
	gemB.setup_gem_type(nextGemB)
