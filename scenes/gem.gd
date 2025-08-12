extends RigidBody2D

@export var gemType : Global.GemType = Global.GemType.Green

var gemDamage : int = 0

var hasBeenCombined : bool = false # this is required by the combining logic in the minigame script

func get_gem_color(type: Global.GemType) -> Color:
	match(type):
		Global.GemType.Green:
			return Color.from_rgba8(0, 182, 77)
		Global.GemType.LightBlue:
			return Color.from_rgba8(16, 187, 244)
		Global.GemType.DarkBlue:
			return Color.from_rgba8(0, 39, 243)
		Global.GemType.Purple:
			return Color.from_rgba8(182, 38, 243)
		Global.GemType.Pink:
			return Color.from_rgba8(255, 120, 188)
		Global.GemType.Red:
			return Color.from_rgba8(232, 63, 33)
		Global.GemType.Orange:
			return Color.from_rgba8(255, 157, 0)
		Global.GemType.Gold:
			return Color.from_rgba8(255, 255, 0)
		_:
			return Color(1, 1, 1, 1)

func get_gem_damage(type: Global.GemType) -> int:
	match(type):
		Global.GemType.Green:
			return 5
		Global.GemType.LightBlue:
			return 10
		Global.GemType.DarkBlue:
			return 25
		Global.GemType.Purple:
			return 50
		Global.GemType.Pink:
			return 100
		Global.GemType.Red:
			return 250
		Global.GemType.Orange:
			return 500
		Global.GemType.Gold:
			return 1000
		_:
			return 0

func setup_gem_type(type: Global.GemType):
	gemType = type
	gemDamage = get_gem_damage(type)
	
	var gemColor = get_gem_color(type)
	%Sprite.set_self_modulate(gemColor)

func setup_gem(type: Global.GemType, gemPos: Vector2):
	position = gemPos
	setup_gem_type(type)
	


func _on_body_entered(body: Node) -> void:
	var isRigidBody = body is RigidBody2D
	if !isRigidBody: return 
	
	var rigidBody = body as RigidBody2D
	var isGem = "gemType" in rigidBody
	if !isGem: return
	
	var otherGem = rigidBody
	
	# Here we know two gems collided. Send event so the game script can handle what happens
	Events.gems_collided.emit(gemType, self, otherGem)
