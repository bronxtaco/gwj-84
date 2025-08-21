extends Node2D

@export var just_for_show := false

@export var gemScene: PackedScene
@export var obstacleScene: PackedScene

@export var maxSpawnedGems : int = 8
@export var gemSpawnTimeInterval : float = 3.0

@export var goalExclusionRadius : float = 35.0

@export var arenaSideCenteringSpeed : float = 20 # speed applied when gem are outside the center polygon

var gemSpawnTimer = gemSpawnTimeInterval
var valid_gem_spawn_locations := []

func spawn_obstacle(spawnPosition: Vector2):
	var obstacle = obstacleScene.instantiate() as Node2D
	obstacle.gem_type = Global.GemType.Heal if Global.active_relics[Global.Relics.ObstaclesDropHealthGems] else Global.GemType.Blue
	%SpawnedObstacles.add_child(obstacle)
	obstacle.position = spawnPosition

func _ready() -> void:
	Events.spawn_combined_gem_type.connect(_on_spawn_combined_gem_type)
	
	# populate gem spawn_locations
	var pos_x = 110.0
	var pos_y
	while pos_x < 670.0:
		pos_y = 240.0
		while pos_y < 540.0:
			var point = Vector2(pos_x, pos_y)
			var inArena = Geometry2D.is_point_in_polygon(point - %ArenaCenterPolygon.position, %ArenaCenterPolygon.polygon)
			if inArena:
				valid_gem_spawn_locations.push_back(point)
			pos_y += 5
		pos_x += 5
	
	if just_for_show:
		spawn_gem(Global.GemType.Blue, [])
		spawn_gem(Global.GemType.Blue, [])
		spawn_gem(Global.GemType.Green, [])
		spawn_gem(Global.GemType.Yellow, [])
		return
	
	Events.fireball_active.connect(_on_fireball_active)
	Events.fireball_inactive.connect(_on_fireball_inactive)
	
	Events.spawn_gem_external.connect(_on_spawn_gem_external)
	
	%Goal.deactivate()
	move_goal()
	
	var usedIndexes = []
	var obstacleCount = Global.current_level + 2 if Global.active_relics[Global.Relics.MoreObstacles] else Global.current_level
	var obstacleCountCapped = min(obstacleCount, %ObstaclePositions.get_child_count())
	for i in range(obstacleCountCapped):
		var obstacleMarkerIndex
		while usedIndexes.size() < obstacleCountCapped:
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
	var mouseIn = Geometry2D.is_point_in_polygon(get_global_mouse_position() - %ArenaPolygon.position, %ArenaPolygon.polygon)
	var c = Color.GREEN if mouseIn else Color.RED
	Events.draw_debug_vector_arrow.emit(Vector2(50,50), Vector2.DOWN, c)
	
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


func spawn_gem_at(gemType: Global.GemType, spawnPos: Vector2, useDropSpawn: bool):
	var dropSpawnImpulseAmount : float = 9.0
	var spawnImpulse = dropSpawnImpulseAmount * gen_random_direction()
	spawn_gem_type(gemType, spawnPos, spawnImpulse, useDropSpawn)


func spawn_gem(gemType: Global.GemType, reservedPositions: Array[Vector2]):
	# find point to spawn gem
	var spawnPos : Vector2
	const gemRadius = 24 # TODO: is there a way to get this direction for un-instantiated scene?
	
	var valid_locations := []
	for loc in valid_gem_spawn_locations:
		var rand_loc = loc + Vector2(randf_range(-3, 3), randf_range(-3, 3))
		var inGoal = Geometry2D.is_point_in_circle(rand_loc, %Goal.position, goalExclusionRadius)
		if !inGoal:
			if !spawn_pos_reserved(reservedPositions, rand_loc, gemRadius) && is_spawn_pos_empty(rand_loc, gemRadius):
				valid_locations.push_back(rand_loc)
	
	if valid_locations.size() == 0:
		print("No valid gem spawn locations found!!! Just use a random one that is inside the staff")
		spawnPos = valid_gem_spawn_locations.pick_random()
	else:
		spawnPos = valid_locations.pick_random()
	
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

func _on_spawn_gem_external(gem_type: Global.GemType, pos: Vector2 = Vector2.INF):
	var reservedPositions : Array[Vector2]
	if pos == Vector2.INF:
		spawn_gem(gem_type, reservedPositions)
	else:
		spawn_gem_at(gem_type, pos, false)

func get_attract_locations():
	return $CritterLocations
