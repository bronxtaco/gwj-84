extends Node2D

var health: int = 4
var invuln: bool = false
var gem_type: Global.GemType

func _ready() -> void:
	if Global.active_relics[Global.Relics.WeakerObstacles]:
		apply_damage(3)
	
	self.modulate = Global.get_gem_color(gem_type)


func apply_damage(amount: int) -> void:
	if invuln:
		return
	invuln = true
	health = max(health - amount, 0)
	print("obstacle damage %d: health %d" % [ amount, health ])
	if health == 0:
		if Global.active_relics[Global.Relics.ObstacleBreakAttackPause]:
			Events.pause_attack.emit(Global.ObstacleBreakAttackPauseMod)
		Events.spawn_gem_external.emit(gem_type, global_position)
		queue_free.call_deferred()
	else:
		%Sprite.frame = clamp(4 - health, 0, 3)
		%BreakEffects.emitting = true
		await get_tree().create_timer(0.3).timeout
		invuln = false
	
