extends Node2D

const SILENT_DB : float = -100
const ZERO_DB : float = 0
const MUSIC_FADE := 1.0

func play_overworld():
	var battle_tween = get_tree().create_tween()
	battle_tween.tween_property(%battle, "volume_db", SILENT_DB, MUSIC_FADE)
	await battle_tween.finished
	%battle.stop()
	%overworld.volume_db = ZERO_DB
	%overworld.play()

func play_battle():
	%overworld.stop()
	%battle_start.play()

func _on_battle_start_finished() -> void:
	%battle.volume_db = ZERO_DB
	%battle.play()
