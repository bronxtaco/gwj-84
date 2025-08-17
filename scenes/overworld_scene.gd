extends Node2D

const CUTSCENE_TIME := 3.0

var remaining_time := CUTSCENE_TIME
var active_path: PathFollow2D
var prev_hero_pos: Vector2

func _ready() -> void:
	var level_path_map = {
		1: %LevelPath01,
		2: %LevelPath02,
		3: %LevelPath03,
		4: %LevelPath04,
		5: %LevelPath05,
	}
	active_path = level_path_map[Global.current_level]
	for child in $PathChildren.get_children():
		child.reparent(active_path, false)
	%HeroSprite.position = Vector2(5.5, -5.5)
	prev_hero_pos = %HeroSprite.global_position
	%CameraLevel.make_current()
	active_path.visible = true
	%HeroSprite.play("idle")
	await get_tree().create_timer(0.2).timeout
	%HeroSprite.play("walking")


func _process(delta: float) -> void:
	remaining_time = max(remaining_time - delta, 0)
	active_path.progress_ratio = 1 - (remaining_time / CUTSCENE_TIME)
	var new_hero_pos = %HeroSprite.global_position
	if new_hero_pos.x > prev_hero_pos.x:
		%HeroSprite.flip_h = false
		%HeroSprite.offset.x = 5.5
	elif new_hero_pos.x < prev_hero_pos.x:
		%HeroSprite.flip_h = true
		%HeroSprite.offset.x = -40.0
	prev_hero_pos = %HeroSprite.global_position
	if remaining_time == 0 or Input.is_action_pressed("skip"):
		Audio.play_battle()
		Scenes.change(Scenes.Enum.Combat)


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.active:
		area.deactivate()
		Global.pickup_relic(area.relic_type)
