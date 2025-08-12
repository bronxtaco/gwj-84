extends Node2D

@export var gemScene: PackedScene

@export var maxSpawnedGems : int = 8
@export var gemSpawnTimeInterval : float = 2.0

@export var gemSpawnMinBounds := Vector2(75.0, 0.0)
@export var gemSpawnMaxBounds := Vector2(725, 350.0)

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
			spawn_gem()

func get_gem_count():
	return %SpawnedGems.get_child_count()

func clear_gems():
	for gem in %SpawnedGems.get_children():
		gem.queue_free()

func spawn_gem_type(gemType: Global.GemType, position: Vector2):
	var gem = gemScene.instantiate() as Node2D
	gem.setup_gem(gemType, position)
	%SpawnedGems.add_child(gem)

func spawn_gem():
	# find point to spawn gem
	var spawnPos : Vector2
	var foundPos = false
	while !foundPos:
		var posX = randf_range(gemSpawnMinBounds.x, gemSpawnMaxBounds.x)
		var posY = randf_range(gemSpawnMinBounds.y, gemSpawnMaxBounds.y)
		var randomPoint = Vector2(posX, posY)
		
		var inArena = Geometry2D.is_point_in_polygon(randomPoint, %ArenaPolygon.polygon)
		var inGoal = Geometry2D.is_point_in_circle(randomPoint, %Goal.position, goalExclusionRadius)	
		if inArena && !inGoal:
			spawnPos = randomPoint
			foundPos = true
	
	# random gem type
	
	var highestSpawnableType = min(Global.GemType.DarkBlue + 1, Global.GemType.size())
	
	var gemType = Global.GemType.values()[randi() % highestSpawnableType]
	spawn_gem_type(gemType, spawnPos)

func _on_goal_body_entered(body: Node2D) -> void:
	var isRigidBody = body is RigidBody2D
	if !isRigidBody: return 
	
	var rigidBody = body as RigidBody2D
	var isGem = "gemType" in rigidBody
	if !isGem: return
	
	var gem = rigidBody
	Events.hero_crit_boost.emit(gem.gemDamage)
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
	
	var nextGemType = min(gemType + 1, Global.GemType.size() - 1)
	gemA.setup_gem_type(nextGemType)
	gemB.setup_gem_type(nextGemType)
	
