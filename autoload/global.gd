extends Node

const HERO_HEALTH := 200

# Menus
enum MENU_TYPE {
	PAUSE,
	SETTINGS,
	AUDIO,
	CREDITS,
}

var paused = false

var game_active := false
var total_run_time := 0.0
var current_level := 1
var hero_health := HERO_HEALTH

var staff_pos := Vector2.ZERO

func reset_game() -> void:
	reset_overworld_relics()
	game_active = false
	total_run_time = 0.0
	current_level = 1
	hero_health = HERO_HEALTH
	Scenes.change(Scenes.Enum.Title)


func reset_overworld_relics():
	var relics_picked := []
	while relics_picked.size() != 4:
		var rand_relic = randi_range(0, Relics.size() - 1)
		if relics_picked.find(rand_relic) == -1:
			relics_picked.push_back(rand_relic)
	overworld_relics = []
	for i in range(4):
		overworld_relics.push_back( { relics_picked[i]: false })

enum GemType
{
	Blue = 0,
	Green,
	Yellow,
	Orange,
	Red,
	
	Multiply, # multiplier
	Divide, # divider
}

func get_gem_color(type: Global.GemType) -> Color:
	match(type):
		Global.GemType.Blue:
			return Color.from_rgba8(16, 187, 244)
		Global.GemType.Green:
			return Color.from_rgba8(0, 223, 38)
		Global.GemType.Yellow:
			return Color.from_rgba8(255, 249, 87)
		Global.GemType.Orange:
			return Color.from_rgba8(255, 157, 0)
		Global.GemType.Red:
			return Color.from_rgba8(232, 63, 33)
		Global.GemType.Multiply:
			return Color.from_rgba8(225, 225, 225)
		Global.GemType.Divide:
			return Color.from_rgba8(225, 225, 225)
		_:
			return Color(1, 1, 1, 1)

func get_gem_damage(type: Global.GemType) -> int:
	match(type):
		Global.GemType.Blue:
			return 8
		Global.GemType.Green:
			return 16
		Global.GemType.Yellow:
			return 32
		Global.GemType.Orange:
			return 64
		Global.GemType.Red:
			return 128
		_:
			return 0

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


enum Relics {
	MoveSpeed,
	GemRankHigherChance,
	GemNoLowestRank,
	HealPostBattle,
	HealingGemChance,
	HealFullOneOff,
	AttackDamageIncrease,
	EnemyAttackDecrease,
	EnemyHealthDecrease,
}

var RelicTextures := {
	Relics.MoveSpeed: preload("res://assets/relics/Celestial spell_17.png"),
	Relics.GemRankHigherChance: preload("res://assets/relics/Galaxy Spell_3.png"),
	Relics.GemNoLowestRank: preload("res://assets/relics/Galaxy Spell_34.png"),
	Relics.HealPostBattle: preload("res://assets/relics/Heal Spell35.png"),
	Relics.HealingGemChance: preload("res://assets/relics/Heal Spell50.png"),
	Relics.HealFullOneOff: preload("res://assets/relics/Heal Spell8.png"),
	Relics.AttackDamageIncrease: preload("res://assets/relics/Fire Spell Pack57.png"),
	Relics.EnemyAttackDecrease: preload("res://assets/relics/Fire Spell Pack71.png"),
	Relics.EnemyHealthDecrease: preload("res://assets/relics/Poison Spell28.png"),
}

var active_relics := {
	Relics.MoveSpeed: false,
	Relics.GemRankHigherChance: false,
	Relics.GemNoLowestRank: false,
	Relics.HealPostBattle: false,
	Relics.HealingGemChance: false,
	Relics.HealFullOneOff: false,
	Relics.AttackDamageIncrease: false,
	Relics.EnemyAttackDecrease: false,
	Relics.EnemyHealthDecrease: false,
}

var overworld_relics := [
	{ Relics.MoveSpeed: true },
	{ Relics.MoveSpeed: true },
	{ Relics.MoveSpeed: true },
	{ Relics.MoveSpeed: true },
]
