extends Node2D

@export var gemScene: PackedScene

@export var maxSpawnedGems : int = 8
@export var gemSpawnTimeInterval : float = 2.0

@export var gemSpawnMinBounds := Vector2(75.0, 0.0)
@export var gemSpawnMaxBounds := Vector2(725, 350.0)

@export var goalExclusionRadius : float = 35.0

var gemSpawnTimer = gemSpawnTimeInterval

func _process(delta: float) -> void:
	gemSpawnTimer -= delta
	
	if gemSpawnTimer <= 0.0:
		gemSpawnTimer = gemSpawnTimeInterval
		if get_gem_count() < maxSpawnedGems:
			spawn_gem()

func get_gem_count():
	return %SpawnedGems.get_child_count()

func spawn_gem():
	# find point to spawn gem
	var spawnPos : Vector2
	var foundPos = false
	while !foundPos:
		var posX = randf_range(gemSpawnMinBounds.x, gemSpawnMaxBounds.x)
		var posY = randf_range(gemSpawnMinBounds.y, gemSpawnMaxBounds.y)
		var randomPoint = Vector2(posX, posY)
		
		var inArena = Geometry2D.is_point_in_polygon( randomPoint, %ArenaPolygon.polygon )
		var inGoal = Geometry2D.is_point_in_circle(randomPoint, %Goal.position, goalExclusionRadius)	
		if inArena && !inGoal:
			spawnPos = randomPoint
			foundPos = true
	
	# random gem type
	var gemType = Global.GemType.values()[randi() % Global.GemType.size()]
	
	var gem = gemScene.instantiate() as Node2D
	gem.setup_gem(gemType, spawnPos)
	
	%SpawnedGems.add_child(gem)

func _on_goal_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		var gem = body as RigidBody2D
		#TODO: gem rules go here. Combine with the current goal color? 
		print("Gem entered goal!")
		var fixedDamageIncrease = 20 # TODO: replace with actual game rules 
		Events.hero_crit_boost.emit(fixedDamageIncrease)
		gem.queue_free()
		
