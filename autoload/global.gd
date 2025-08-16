extends Node

const HERO_HEALTH := 20

# Menus
enum MENU_TYPE {
	PAUSE,
	SETTINGS,
	CREDITS,
}

var paused = false

var game_active := false
var total_run_time := 0.0
var current_level := 1
var hero_health := HERO_HEALTH

var staff_pos := Vector2.ZERO


func reset_game() -> void:
	game_active = false
	total_run_time = 0.0
	current_level = 1
	hero_health = HERO_HEALTH
	Scenes.change(Scenes.Enum.Title)


enum GemType
{
	# Basic Gem
	Red = 0,
	Blue,
	
	# Upgraded colors
	Orange,
	Green,
	
	Gold, # Max color
	
	White, # multiplier
	Black, # divider
}

func get_gem_color(type: Global.GemType) -> Color:
	match(type):
		Global.GemType.Red:
			return Color.from_rgba8(232, 63, 33)
		Global.GemType.Blue:
			return Color.from_rgba8(16, 187, 244)
		Global.GemType.Orange:
			return Color.from_rgba8(255, 157, 0)
		Global.GemType.Green:
			return Color.from_rgba8(0, 223, 38)# Color.from_rgba8(0, 182, 77)
		Global.GemType.Gold:
			return Color.from_rgba8(232, 223, 38)
		Global.GemType.White:
			return Color.from_rgba8(0, 39, 243)
		Global.GemType.Black:
			return Color.from_rgba8(30, 30, 30)
		_:
			return Color(1, 1, 1, 1)

var Enemies = {
	1: preload("res://scenes/enemy_dwarf.tscn"),
	2: preload("res://scenes/enemy_bear.tscn"),
	3: preload("res://scenes/enemy_vampire.tscn"),
	4: preload("res://scenes/enemy_knight.tscn"),
	5: preload("res://scenes/enemy_orc.tscn"),
}

func get_formatted_time(time_seconds: float, with_ms: bool = false) -> String:
	var ms = floor(fmod(time_seconds * 1000.0, 1000.0))
	var seconds = floor(fmod(time_seconds, 60.0))
	var minutes = floor(time_seconds / 60.0)

	if with_ms:
		return "%02d:%02d.%03d" % [minutes, seconds, ms]

	return "%02d:%02d" % [minutes, seconds]
