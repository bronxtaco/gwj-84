extends Node2D

var health: int = 4
var invuln: bool = false

func _ready() -> void:
	if Global.active_relics[Global.Relics.WeakerObstacles]:
		apply_damage(3)

func apply_damage(amount: int) -> void:
	if invuln:
		return
	invuln = true
	health = max(health - amount, 0)
	print("obstacle damage %d: health %d" % [ amount, health ])
	if health == 0:
		queue_free.call_deferred()
	else:
		%Sprite.frame = clamp(4 - health, 0, 3)
		%BreakEffects.emitting = true
		await get_tree().create_timer(0.3).timeout
		invuln = false
	
