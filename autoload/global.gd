extends Node

# Menus
enum MENU_TYPE {
	PAUSE,
	SETTINGS,
	CREDITS,
}

var paused = false

var current_level := 1

var staff_pos := Vector2.ZERO


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
