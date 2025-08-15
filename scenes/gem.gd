extends RigidBody2D

@export var gemType : Global.GemType = Global.GemType.Green

var gemDamage : int = 0

var dropOnSpawnTween

var initialCollisionLayers : int = 0
var initialCollisionMasks : int = 0

func _ready():
	dropOnSpawnTween = create_tween()
	initialCollisionLayers = get_collision_layer()
	initialCollisionMasks = get_collision_mask()

func get_gem_damage(type: Global.GemType) -> int:
	match(type):
		Global.GemType.Red,Global.GemType.Blue:
			return 10
		Global.GemType.Orange, Global.GemType.Green:
			return 20
		Global.GemType.Gold:
			return 50
		_:
			return 0

func setup_gem_type(type: Global.GemType):
	gemType = type
	gemDamage = get_gem_damage(type)
	
	var gemColor = Global.get_gem_color(type)
	%Sprite.set_self_modulate(gemColor)


func setup_gem(type: Global.GemType, gemPos: Vector2):
	global_position = gemPos # set the gem in the right spot, but offset the gem sprite in anim
	set_collision_layer(0)
	set_collision_mask(0)
	
	var initSpriteYPos = %Sprite.position.y
	%Sprite.position.y = -300
	
	var initShadowScale = $Shadow.scale
	$Shadow.scale = Vector2(0, 0)
	
	var initScale
	
	var dropSpawnTime = 0.5
	
	dropOnSpawnTween.play()
	dropOnSpawnTween.tween_property(%Sprite, "position:y", initSpriteYPos, dropSpawnTime)
	dropOnSpawnTween.parallel().tween_property(%Shadow, "scale", initShadowScale, dropSpawnTime)
	
	dropOnSpawnTween.tween_callback(on_tween_end)
	
	setup_gem_type(type)

func on_tween_end():
	set_collision_layer(initialCollisionLayers)
	set_collision_mask(initialCollisionMasks)
	
	# give it some slight random impulse direction on landing
	var impulseSpeed = 9
	
	# my dumb way to get rid of zero length direction. But it works :D 
	var randDir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	while randDir.length_squared() == 0:
		randDir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		
	var impulseDirection = randDir.normalized()
	apply_central_impulse(impulseDirection * impulseSpeed)

func _on_body_entered(body: Node) -> void:
	var isRigidBody = body is RigidBody2D
	if !isRigidBody: return 
	
	var rigidBody = body as RigidBody2D
	var isGem = "gemType" in rigidBody
	if !isGem: return
	
	var otherGem = rigidBody
	
	# Here we know two gems collided. Send event so the game script can handle what happens
	Events.gems_collided.emit(gemType, self, otherGem)
