extends Node2D

const travel_time := 0.5
const rps := 2.0

var gem_type: Global.GemType

func initialize(gem_type_) -> void:
	gem_type = gem_type_

func _ready() -> void:
	var gemColor = Global.get_gem_color(gem_type)
	%Sprite.modulate = gemColor

func start(dest_pos: Vector2) -> void:
	create_tween().tween_property(self, "global_position", dest_pos, travel_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	await get_tree().create_timer(0.2).timeout
	$SFX.play()

func _process(delta: float) -> void:
	%Sprite.rotation_degrees += (360 * rps) / delta
