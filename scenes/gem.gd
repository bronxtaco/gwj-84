extends RigidBody2D

@export var gemType : Global.GemType = Global.GemType.Blue

@export var  dropSpawnTime : float = 0.5

var gemDamage : int = 0

var useDropSpawn : bool = true

var spawnImpulse : Vector2

var dropOnSpawnTween

var initialCollisionLayers : int = 0
var initialCollisionMasks : int = 0



func _ready():
	dropOnSpawnTween = create_tween()
	initialCollisionLayers = get_collision_layer()
	initialCollisionMasks = get_collision_mask()

func set_damage_number(type: Global.GemType):
	gemDamage = Global.get_gem_damage(type)
	
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

func setup_gem(type: Global.GemType, gemPos: Vector2, spawnImpulse: Vector2, useDropSpawn: bool):
	global_position = gemPos # set the gem in the right spot, but offset the gem sprite in anim
	
	gemType = type
	
	set_damage_number(type)
	
	
	%Sprite.set_self_modulate(Global.get_gem_color(type))
	%DamageNumberLabel.set_self_modulate(Global.get_gem_color(type))
	%CollideParticle.color = Global.get_gem_color(type)
	self.useDropSpawn = useDropSpawn
	self.spawnImpulse = spawnImpulse
	
	if !useDropSpawn:
		apply_central_impulse(spawnImpulse)
		%CollideParticle.emitting = true # one shot, play/emmits once
	else: #drop spawn
		set_collision_layer(0)
		set_collision_mask(0)
		
		var initSpriteYPos = %Sprite.position.y
		var initShadowScale = $Shadow.scale
		%Sprite.position.y = -300
		$Shadow.scale = Vector2(0, 0)
		
		dropOnSpawnTween.play()
		dropOnSpawnTween.tween_property(%Sprite, "position:y", initSpriteYPos, dropSpawnTime)
		dropOnSpawnTween.parallel().tween_property(%Shadow, "scale", initShadowScale, dropSpawnTime)
		dropOnSpawnTween.tween_callback(on_tween_end)

func on_tween_end():
	if useDropSpawn: # not really required as callback will never happen, but just incase someone else calls this
		set_collision_layer(initialCollisionLayers)
		set_collision_mask(initialCollisionMasks)
		apply_central_impulse(spawnImpulse) # apply spawn impulse after the gem has landed

var removingGem : bool = false

func remove_gem():
	removingGem = true
	set_collision_layer(0)
	set_collision_mask(0)
	queue_free()

func play_collide_sound():
	%CollideSound.play()

func play_upgrade_sound():
	%UpgradeSound.play()

func _on_body_entered(body: Node) -> void:
	if removingGem: return
	
	var isRigidBody = body is RigidBody2D
	if !isRigidBody: return 
	
	var rigidBody = body as RigidBody2D
	var isGem = "gemType" in rigidBody
	if !isGem: return
	
	var otherGem = rigidBody
	
	# Here we know two gems collided. Send event so the game script can handle what happens
	Events.gems_collided.emit(gemType, self, otherGem)
