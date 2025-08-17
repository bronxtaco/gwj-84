extends Node2D

const SILENT_DB : float = -100
const MUSIC_DB : float = -8
const MUSIC_FADE := 1.0

enum MusicPlaying {
	None,
	Title,
	Overworld,
	Battle,
}
var music_playing := MusicPlaying.None

func play_overworld():
	if music_playing == MusicPlaying.Overworld:
		return
	
	music_playing = MusicPlaying.Overworld
	var battle_tween = get_tree().create_tween()
	battle_tween.tween_property(%battle, "volume_db", SILENT_DB, MUSIC_FADE)
	await battle_tween.finished
	
	if music_playing == MusicPlaying.Overworld:
		%battle.stop()
		%overworld.volume_db = MUSIC_DB
		%overworld.play()

func play_battle():
	if music_playing != MusicPlaying.Battle:
		music_playing = MusicPlaying.Battle
		%overworld.stop()
		%battle_start.play()

func play_victory():
	music_playing = MusicPlaying.None
	%battle.stop()
	%victory.play()

func play_gameover():
	music_playing = MusicPlaying.None
	%battle.stop()
	%gameover.play()

func _on_battle_start_finished() -> void:
	%battle.volume_db = MUSIC_DB
	%battle.play()
	

func play_menu_pause():
	%pause.play()
	
func play_menu_select():
	%select.play()

func play_menu_back():
	%back.play()

func play_menu_scroll():
	%scroll.play()

func play_relic_pickup():
	%relic_pickup.play()
