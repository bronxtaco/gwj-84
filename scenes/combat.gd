extends Node2D

var level01_bg = preload("res://assets/combat/backgrounds/game_background_1.png")
var level02_bg = preload("res://assets/combat/backgrounds/game_background_6.png")
var level03_bg = preload("res://assets/combat/backgrounds/game_background_8.png")
var level04_bg = preload("res://assets/combat/backgrounds/game_background_2.png")
var level05_bg = preload("res://assets/combat/backgrounds/game_background_5.png")
var level_bg_map = {
	1: level01_bg,
	2: level02_bg,
	3: level03_bg,
	4: level04_bg,
	5: level05_bg,
}

@onready var Hero = $Hero
@onready var BattleEndText = %BattleEndText

var Enemy # set on ready

# StateMachine
enum STATE {
	Idle,
	HeroAttack,
	HeroDefence,
	Defeat,
	Victory,
}
var fsm := FSM.StateMachine.new(STATE, STATE.Idle, self, "Combat")

class IdleState extends FSM.State:
	const STATE_TIME := 3.0 # the downtime between attacks
	var next_state: STATE
	
	func on_enter(prev_state):
		next_state = STATE.HeroAttack # hero always attacks first
		if prev_state != null:        # and then alternates
			next_state = STATE.HeroAttack if prev_state == STATE.HeroDefence else STATE.HeroDefence
	
	func get_next_state():
		if seconds_active > STATE_TIME:
			return next_state


class HeroAttackState extends FSM.State:
	func on_enter(prev_state):
		obj.Hero.start_attack()
	
	func get_next_state():
		if obj.Hero.is_idle():
			return STATE.Idle


class HeroDefenceState extends FSM.State:
	func on_enter(prev_state):
		obj.Enemy.start_attack()
	
	func get_next_state():
		if obj.Enemy.is_idle():
			return STATE.Idle


class DefeatState extends FSM.State:
	const STATE_TIME := 4.0
	var exit_triggered := false
	func on_enter(prev_state):
		exit_triggered = false
		obj.BattleEndText.text = "Your owner died!"
		obj.BattleEndText.visible = true
		print("Hero has been defeated!")
	
	func force_state_change():
		return Global.hero_health <= 0
	
	func physics_process(_delta):
		if !exit_triggered and seconds_active >= STATE_TIME:
			exit_triggered = true
			obj.level_fail()


class VictoryState extends FSM.State:
	const STATE_TIME := 4.0
	var exit_triggered := false
	func on_enter(prev_state):
		exit_triggered = false
		obj.BattleEndText.text = "Enemy Defeated!"
		obj.BattleEndText.visible = true
		obj.Hero.battle_victory()
		print("Hero has slain the enemy!")
	
	func force_state_change():
		return obj.Enemy.currentHealth <= 0
	
	func physics_process(_delta):
		if !exit_triggered and seconds_active >= STATE_TIME:
			exit_triggered = true
			obj.level_success()


func _ready():
	Events.apply_damage_to_enemy.connect(_on_apply_damage_to_enemy)
	Events.apply_damage_to_hero.connect(_on_apply_damage_to_hero)
	
	fsm.debug = true # enables logging for state changes
	fsm.register_state(STATE.Idle, IdleState)
	fsm.register_state(STATE.HeroAttack, HeroAttackState)
	fsm.register_state(STATE.HeroDefence, HeroDefenceState)
	fsm.register_state(STATE.Defeat, DefeatState)
	fsm.register_state(STATE.Victory, VictoryState)
	
	Enemy = Global.Enemies[Global.current_level].instantiate()
	$EnemyContainer.add_child(Enemy)
	
	%BackgroundFlipped.texture = level_bg_map[Global.current_level]
	%Background.texture = level_bg_map[Global.current_level]


func _physics_process(delta: float):
	fsm.physics_process(delta)
	
	if Input.is_action_just_pressed("debug_f6"):
		level_success()


func level_success() -> void:
	Global.current_level += 1
	Audio.play_overworld()
	Scenes.change(Scenes.Enum.Overworld)

func level_fail() -> void:
	Global.reset_game()


func _on_apply_damage_to_enemy(amount: int):
	Enemy.apply_damage(amount)
	
func _on_apply_damage_to_hero(amount: int):
	Hero.apply_damage(amount)
