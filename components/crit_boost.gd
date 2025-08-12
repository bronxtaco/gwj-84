extends Node2D

const travel_time := 0.5
const rps := 2.0

func start(dest_pos: Vector2) -> void:
	get_tree().create_tween().tween_property(self, "global_position", dest_pos, travel_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)

func _process(delta: float) -> void:
	$Sprite2D.rotation_degrees += (360 * rps) / delta
