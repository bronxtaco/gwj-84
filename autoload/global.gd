extends Node

# Menus
enum MENU_TYPE {
	PAUSE,
	SETTINGS,
	CREDITS,
}

var paused = false

var current_level := 1


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
