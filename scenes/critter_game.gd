extends Node2D

@export var gemScenes: Array[PackedScene]

@export var maxSpawnedGems : int = 8
@export var gemSpawnTimeInterval : float = 2.0

@export var gemSpawnMinX : float = 50.0
@export var gemSpawnMaxX : float = 750.0

@export var gemSpawnMinY : float = 300.0
@export var gemSpawnMaxY : float = 575.0

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
	if gemScenes.size() <= 0: 
		printerr("no gem scenes existed for spawn_gem to use")
		return
		
	var gemRandomIndex = randi() % gemScenes.size()
	var gemScene = gemScenes[gemRandomIndex]
	
	var gem = gemScene.instantiate() as Node2D
	
	var posX = randf_range(gemSpawnMinX, gemSpawnMaxX)
	var posY = randf_range(gemSpawnMinY, gemSpawnMaxY)
	
	PhysicsShapeQueryParameters2D
	
	gem.position = Vector2(posX, posY)
	
	%SpawnedGems.add_child(gem)

func _on_goal_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		var gem = body as RigidBody2D
		#TODO: add to damage here
		print("Gem entered goal!")
		gem.queue_free()
		
