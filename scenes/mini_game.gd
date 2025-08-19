extends Node2D

@export var just_for_show := false

@export var gemScene: PackedScene
@export var obstacleScene: PackedScene

@export var maxSpawnedGems : int = 8
@export var gemSpawnTimeInterval : float = 3.0

@export var gemSpawnMinBounds := Vector2(0.0, 0.0)
@export var gemSpawnMaxBounds := Vector2(800, 600.0)

@export var goalExclusionRadius : float = 35.0

@export var arenaSideCenteringSpeed : float = 20 # speed applied when gem are outside the center polygon

var gemSpawnTimer = gemSpawnTimeInterval

func spawn_obstacle(spawnPosition: Vector2):
	var obstacle = obstacleScene.instantiate() as Node2D
	%SpawnedObstacles.add_child(obstacle)
	obstacle.position = spawnPosition

func _ready() -> void:
	Events.spawn_combined_gem_type.connect(_on_spawn_combined_gem_type)
	
	if just_for_show:
		spawn_gem(Global.GemType.Blue, [])
		spawn_gem(Global.GemType.Blue, [])
		spawn_gem(Global.GemType.Green, [])
		spawn_gem(Global.GemType.Yellow, [])
		return
	
	Events.fireball_active.connect(_on_fireball_active)
	Events.fireball_inactive.connect(_on_fireball_inactive)
	
	Events.spawn_kill_gem.connect(_on_spawn_kill_gem)
	
	%Goal.deactivate()
	move_goal()
	
	var usedIndexes = []
	var obstacleCount = min(Global.current_level, %ObstaclePositions.get_child_count())
	for i in range(obstacleCount):
		var obstacleMarkerIndex
		while usedIndexes.size() < Global.current_level:
			obstacleMarkerIndex = randi_range(0,  %ObstaclePositions.get_child_count() - 1)
			if usedIndexes.find(obstacleMarkerIndex) == -1:
				usedIndexes.push_back(obstacleMarkerIndex)
				var obstacleMarker = %ObstaclePositions.get_children()[obstacleMarkerIndex] as Marker2D
				spawn_obstacle(obstacleMarker.position)

func move_goal():
	var randChildIndex = randi_range(0,  %GoalPositions.get_child_count() - 1)
	var goalPosMarker = %GoalPositions.get_children()[randChildIndex] as Marker2D
	%Goal.position = goalPosMarker.position
	
func get_gem_type() -> Global.GemType:
	if Global.active_relics[Global.Relics.HealingGemChance]:
		var rng = randi_range(1, 30)
		if rng == 30:
			return Global.GemType.Heal
	
	var gemType = Global.GemType.Green if Global.active_relics[Global.Relics.GemNoLowestRank] else Global.GemType.Blue
	if Global.active_relics[Global.Relics.GemRankHigherChance]:
		var rng = randi_range(1, 200)
		if rng > 199:
			gemType = Global.GemType.Red
		elif rng > 195:
			gemType = Global.GemType.Orange
		elif rng > 180:
			gemType = Global.GemType.Yellow
		elif rng > 150:
			gemType = Global.GemType.Green
		# else remain Blue (or Green)
	return gemType


func _process(delta: float) -> void:
	# reserve spawn positions in a single group of spawns. So if 3 spawns are made, non of them overlap	
	var reservedSpawnPositions : Array[Vector2]
	
	var gem_spawn_time_interval = gemSpawnTimeInterval * 0.35 if Global.active_relics[Global.Relics.IncreaseGemSpawnRate] else gemSpawnTimeInterval
	var max_spawned_gems = maxSpawnedGems + 2 if Global.active_relics[Global.Relics.IncreaseGemSpawnMax] else maxSpawnedGems
	
	gemSpawnTimer -= delta
	if gemSpawnTimer <= 0.0 && (just_for_show or Global.mini_game_active):
		gemSpawnTimer = gem_spawn_time_interval
		
		var gemCount = get_gem_count()
		if gemCount < max_spawned_gems:
			var spawnCount = min(randi_range(1, 3), max_spawned_gems - gemCount)
			if gemCount == 0:
				spawnCount = min(spawnCount, 2) # always spawn at least two gems if none exist
			
			for i in range(spawnCount):
				var gemType = get_gem_type()
				spawn_gem(gemType, reservedSpawnPositions)


func _physics_process(delta: float) -> void:
	# loop over all gems and if they are outside the arena center polygon, nudge them back inside
	for gemNode in %SpawnedGems.get_children():
		var gem = gemNode as RigidBody2D
		var inCenterPlaySpace = Geometry2D.is_point_in_polygon(gem.position - %ArenaCenterPolygon.position, %ArenaCenterPolygon.polygon)
		if !inCenterPlaySpace:
			var gemSpeed = gem.linear_velocity.length()
			if gemSpeed < arenaSideCenteringSpeed:
				var speedToAdd = max( arenaSideCenteringSpeed - gemSpeed, 0.0)
				var toCenterDir = (%ArenaCenter.position - gem.position).normalized()
				gem.apply_force(toCenterDir * speedToAdd)

func get_gem_count():
	return %SpawnedGems.get_child_count()

func get_random_gem():
	if %SpawnedGems.get_child_count() > 0:
		return %SpawnedGems.get_children().pick_random()

func clear_gems():
	for gem in %SpawnedGems.get_children():
		gem.queue_free()

func _on_spawn_combined_gem_type(gemType: Global.GemType, position_: Vector2, impulse: Vector2, useDropSpawn: bool):
	var new_gem = spawn_gem_type(gemType, position_, impulse, useDropSpawn)
	Audio.play_gem_combine()

func spawn_gem_type(gemType: Global.GemType, position: Vector2, impulse: Vector2, useDropSpawn: bool):
	var gem = gemScene.instantiate() as Node2D
	%SpawnedGems.add_child.call_deferred(gem)
	gem.setup_gem.call_deferred(gemType, position, impulse, useDropSpawn)
	return gem

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

func spawn_pos_reserved(reservedPositions: Array[Vector2], testPos: Vector2, gemRadius: float) -> bool:
	var gemDiameter = gemRadius * 2.0
	var gemDiameterSqr = gemDiameter * gemDiameter
	
	for pos in reservedPositions:
		if pos.distance_squared_to(testPos) <= gemDiameterSqr:
			return true
	return false

func spawn_gem(gemType: Global.GemType, reservedPositions: Array[Vector2]):
	# find point to spawn gem
	var spawnPos : Vector2
	var foundPos = false
	
	var gemRadius = 24 # TODO: is there a way to get this direction for un-instantiated scene?
	
	var maxPosSearches = 64 #
	while maxPosSearches > 0:
		maxPosSearches -= 1
		
		var posX = randf_range(gemSpawnMinBounds.x, gemSpawnMaxBounds.x)
		var posY = randf_range(gemSpawnMinBounds.y, gemSpawnMaxBounds.y)
		var randomPoint = Vector2(posX, posY)
		
		var inArena = Geometry2D.is_point_in_polygon(randomPoint - %ArenaPolygon.position, %ArenaPolygon.polygon)
		var inGoal = Geometry2D.is_point_in_circle(randomPoint, %Goal.position, goalExclusionRadius)	
		if inArena && !inGoal:
			if !spawn_pos_reserved(reservedPositions, randomPoint, gemRadius) && is_spawn_pos_empty(randomPoint, gemRadius):
				spawnPos = randomPoint
				break # break out of while loop, as we found a pos
	
	var dropSpawnImpulseAmount : float = 9.0
	var spawnImpulse = dropSpawnImpulseAmount * gen_random_direction()
	
	# random gem type
	spawn_gem_type(gemType, spawnPos, spawnImpulse, true)
	
	reservedPositions.append(spawnPos)


func _on_fireball_active():
	move_goal()
	%Goal.activate()
	
func _on_fireball_inactive():
	%Goal.deactivate()

func gen_random_direction() -> Vector2:
	# my dumb way to get rid of zero length direction. But it works :D 
	var randDir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	while randDir.length_squared() == 0:
		randDir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	return randDir.normalized()

func _on_spawn_kill_gem():
	var reservedPositions : Array[Vector2]
	spawn_gem(Global.GemType.KillGem, reservedPositions)

func get_attract_locations():
	return $CritterLocations
