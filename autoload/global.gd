extends Node

const HeroStartingHealth := 200

# Menus
enum MENU_TYPE {
	PAUSE,
	SETTINGS,
	AUDIO,
	CREDITS,
	RELIC_PICKUP,
	DEBUG_RELIC,
}

var paused := false
var hud_enabled := false

var mini_game_active := false

var game_active := false
var total_run_time := 0.0
var current_level := 1
var hero_max_health := HeroStartingHealth
var hero_health := HeroStartingHealth
var cheater := false

var staff_pos := Vector2.ZERO

func _ready() -> void:
	reset_game()

func reset_game() -> void:
	reset_relics()
	Events.refresh_hud.emit()
	game_active = false
	total_run_time = 0.0
	current_level = 1
	hero_max_health = HeroStartingHealth
	hero_health = HeroStartingHealth
	cheater = false
	Scenes.change(Scenes.Enum.Title)


func reset_relics():
	relic_pickup_order = []
	active_relics = {
		Relics.MoveSpeed: false,
		Relics.GemRankHigherChance: false,
		Relics.GemNoLowestRank: false,
		Relics.HealPostBattle: false,
		Relics.HealingGemChance: false,
		Relics.IncreaseHeroMaxHealth: false,
		Relics.AttackDamageIncrease: false,
		Relics.EnemyAttackDecrease: false,
		Relics.EnemyHealthDecrease: false,
		Relics.IncreaseGemSpawnRate: false,
		Relics.IncreaseGemSpawnMax: false,
		Relics.WeakerObstacles: false,
		Relics.SlowerAttacks: false,
		Relics.FirstDamageHalved: false,
		Relics.MoreObstacles: false,
		Relics.ObstaclesDropHealthGems: false,
	}
	Events.refresh_hud.emit()
	var relics_picked := []
	while relics_picked.size() != 4:
		var rand_relic = randi_range(0, Relics.size() - 1)
		if relics_picked.find(rand_relic) == -1:
			relics_picked.push_back(rand_relic)
	overworld_relics = []
	for i in range(4):
		overworld_relics.push_back( { "type": relics_picked[i], "active": true })

enum GemType
{
	Blue = 0,
	Green,
	Yellow,
	Orange,
	Red,
	Ultra,
	
	Multiply, # multiplier
	Divide, # divider
	Heal,
	
	KillGem
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
		Global.GemType.Ultra:
			return Color.hex(0x90538dff)
		Global.GemType.Multiply:
			return Color.from_rgba8(225, 225, 225)
		Global.GemType.Divide:
			return Color.from_rgba8(225, 225, 225)
		Global.GemType.Heal:
			return Color.DEEP_PINK
		Global.GemType.KillGem:
			return Color.DARK_RED
		_:
			return Color(1, 1, 1, 1)

func get_gem_damage(type: Global.GemType) -> int:
	match(type):
		Global.GemType.Blue:
			return 1
		Global.GemType.Green:
			return 4
		Global.GemType.Yellow:
			return 12
		Global.GemType.Orange:
			return 30
		Global.GemType.Red:
			return 80
		Global.GemType.Ultra:
			return 200
		Global.GemType.Heal:
			return 10
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
	IncreaseHeroMaxHealth,
	AttackDamageIncrease,
	EnemyAttackDecrease,
	EnemyHealthDecrease,
	IncreaseGemSpawnRate,
	IncreaseGemSpawnMax,
	WeakerObstacles,
	SlowerAttacks,
	FirstDamageHalved,
	MoreObstacles,
	ObstaclesDropHealthGems,
}

var RelicTextures := {
	Relics.MoveSpeed: preload("res://assets/relics/Celestial spell_17.png"),
	Relics.GemRankHigherChance: preload("res://assets/relics/Galaxy Spell_3.png"),
	Relics.GemNoLowestRank: preload("res://assets/relics/Galaxy Spell_34.png"),
	Relics.HealPostBattle: preload("res://assets/relics/Heal Spell35.png"),
	Relics.HealingGemChance: preload("res://assets/relics/Heal Spell50.png"),
	Relics.IncreaseHeroMaxHealth: preload("res://assets/relics/Heal Spell8.png"),
	Relics.AttackDamageIncrease: preload("res://assets/relics/Fire Spell Pack57.png"),
	Relics.EnemyAttackDecrease: preload("res://assets/relics/Fire Spell Pack71.png"),
	Relics.EnemyHealthDecrease: preload("res://assets/relics/Poison Spell28.png"),
	Relics.IncreaseGemSpawnRate: preload("res://assets/relics/Galaxy Spell_48.png"),
	Relics.IncreaseGemSpawnMax: preload("res://assets/relics/Galaxy Spell_32.png"),
	Relics.WeakerObstacles: preload("res://assets/relics/Stone Spells75.png"),
	Relics.SlowerAttacks: preload("res://assets/relics/Ice Spells54.png"),
	Relics.FirstDamageHalved: preload("res://assets/relics/Water Spell_56.png"),
	Relics.MoreObstacles: preload("res://assets/relics/Celestial spell_62.png"),
	Relics.ObstaclesDropHealthGems: preload("res://assets/relics/Blood Spell_70.png"),
}

var RelicNames := {
	Relics.MoveSpeed: "1,000 MORE LEGS",
	Relics.GemRankHigherChance: "LUCKY CRITTER",
	Relics.GemNoLowestRank: "NO MORE FEELING BLUE",
	Relics.HealPostBattle: "POST-MATCH REFRESHMENTS",
	Relics.HealingGemChance: "HEALING RAIN",
	Relics.IncreaseHeroMaxHealth: "UBER HERO",
	Relics.AttackDamageIncrease: "STOKE THE FIRE",
	Relics.EnemyAttackDecrease: "QUELL THE FLAMES",
	Relics.EnemyHealthDecrease: "SAP STRENGTH",
	Relics.IncreaseGemSpawnRate: "HEAVY RAIN",
	Relics.IncreaseGemSpawnMax: "TOP OF THE PYRAMID",
	Relics.WeakerObstacles: "THE PARTHENON",
	Relics.SlowerAttacks: "BULLET TIME",
	Relics.FirstDamageHalved: "ALPHA SHIELD",
	Relics.MoreObstacles: "BUMPY ROAD",
	Relics.ObstaclesDropHealthGems: "HEALTHY OUTLOOK",
}

var RelicDescriptions := {
	Relics.MoveSpeed: "Increased movement speed",
	Relics.GemRankHigherChance: "Chance for higher tier crystal drops",
	Relics.GemNoLowestRank: "Lowest tier crystals no longer spawn",
	Relics.HealPostBattle: "Heal some amount after each battle",
	Relics.HealingGemChance: "Chance for healing crystals to spawn",
	Relics.IncreaseHeroMaxHealth: "Max health increase",
	Relics.AttackDamageIncrease: "Hero fireball starting damage increase",
	Relics.EnemyAttackDecrease: "Enemy fireball starting damage decrease",
	Relics.EnemyHealthDecrease: "Enemy health decrease",
	Relics.IncreaseGemSpawnRate: "Crystals spawn faster",
	Relics.IncreaseGemSpawnMax: "Max crystal spawns increase",
	Relics.WeakerObstacles: "Static crystals have reduced health",
	Relics.SlowerAttacks: "Fireball movement speed decrease",
	Relics.FirstDamageHalved: "First damage taken each battle is halved",
	Relics.MoreObstacles: "Number of static crystals increased",
	Relics.ObstaclesDropHealthGems: "Static crystals drop health crystals",
}

var active_relics := {}
var relic_pickup_order := []

var overworld_relics := [
	{ "type": Relics.MoveSpeed, "active": true },
	{ "type": Relics.MoveSpeed, "active": true },
	{ "type": Relics.MoveSpeed, "active": true },
	{ "type": Relics.MoveSpeed, "active": true },
]

const SlowerAttacksMod := 1.3
const MaxHealthMod := 50
var recent_relic_pickup: Relics
func pickup_relic(relic_type: Relics, debug: bool = false):
	active_relics[relic_type] = true
	relic_pickup_order.push_back(relic_type)
	Events.refresh_hud.emit()
	
	# on pickup relic stuff, most don't need to do anything here
	if relic_type == Relics.IncreaseHeroMaxHealth:
		hero_max_health += MaxHealthMod
		hero_health += MaxHealthMod
		Events.hero_health_changed.emit()
	
	if !debug:
		recent_relic_pickup = relic_type
		Events.menu_push.emit(MENU_TYPE.RELIC_PICKUP)


func drop_relic(relic_type: Relics, debug: bool = true):
	active_relics[relic_type] = false
	for i in range(relic_pickup_order.size()):
		if relic_pickup_order[i] == relic_type:
			relic_pickup_order.remove_at(i)
			break
	Events.refresh_hud.emit()
	
	# on drop relic stuff, most don't need to do anything here
	if relic_type == Relics.IncreaseHeroMaxHealth:
		hero_max_health = max(hero_max_health - MaxHealthMod, 1)
		hero_health = max(hero_health - MaxHealthMod, 1)
		Events.hero_health_changed.emit()
