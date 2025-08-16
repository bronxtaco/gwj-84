extends Node2D

const walk_time := 2.0
var prev_pos: Vector2 = Vector2.ZERO

func _on_timer_timeout() -> void:
	$Timer.wait_time = walk_time + randf_range(0.5, 1.5)
	var i = randi() % $CritterLocations.get_child_count()
	var target_pos = $CritterLocations.get_child(i)
	var x_diff = target_pos.global_position.x - prev_pos.x
	var y_diff = target_pos.global_position.y - prev_pos.y
	if abs(x_diff) > abs(y_diff):
		%CritterSprite.play("walk_right")
		%CritterSprite.flip_h = x_diff < 0
	else:
		if y_diff > 0:
			%CritterSprite.play("walk_down")
		else:
			%CritterSprite.play("walk_up")
	prev_pos = target_pos.global_position
	var tween = create_tween().tween_property(%CritterSprite, "global_position", target_pos.global_position, walk_time)
	await tween.finished
	%CritterSprite.stop()
