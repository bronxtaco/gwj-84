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
@onready var GameWinText1 = %GameWinText1
@onready var GameWinText2 = %GameWinText2
@onready var GameWinText3 = %GameWinText3

var Enemy # set on ready

var first_hero_damage_taken := false

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
		Global.mini_game_active = true
		if prev_state != null:        # and then alternates
			next_state = STATE.HeroAttack if prev_state == STATE.HeroDefence else STATE.HeroDefence
	
	func get_next_state():
		if seconds_active > STATE_TIME:
			return next_state


class HeroAttackState extends FSM.State:
	var spawned_kill_gem : bool = false
	
	func on_enter(prev_state):
		spawned_kill_gem = false
		obj.Hero.start_attack()
	
	func get_next_state():
		if obj.Hero.is_idle():
			return STATE.Idle

	func physics_process(_delta):
		if !spawned_kill_gem && obj.Hero.get_fireball_damage() >= obj.Enemy.currentHealth:
			Events.spawn_gem_external.emit(Global.GemType.KillGem)
			spawned_kill_gem = true

class HeroDefenceState extends FSM.State:
	func on_enter(prev_state):
		obj.Enemy.start_attack()
	
	func get_next_state():
		if obj.Enemy.is_idle():
			return STATE.Idle


class DefeatState extends FSM.State:
	var exit_triggered := false
	func on_enter(prev_state):
		exit_triggered = false
		Global.mini_game_active = false
		Audio.play_gameover()
		obj.BattleEndText.text = "Noooooooooooo!"
		await obj.get_tree().create_timer(0.25).timeout
		obj.BattleEndText.visible = true
		print("Hero has been defeated!")
		Global.game_active = false
	
	func force_state_change():
		return Global.hero_health <= 0
	
	func physics_process(_delta):
		if !exit_triggered and Input.is_action_just_pressed("ui_accept"):
			exit_triggered = true
			obj.level_fail()


class VictoryState extends FSM.State:
	const STATE_TIME := 4.0
	var exit_triggered := false
	func on_enter(prev_state):
		exit_triggered = false
		Global.mini_game_active = false
		obj.Hero.battle_victory()
		if Global.active_relics[Global.Relics.HealPostBattle]:
			obj.Hero.heal(30)
		
		Audio.play_victory()
		if Global.current_level == 5: # game has been won
			Global.game_active = false
			var run_time = Global.get_formatted_time(Global.total_run_time, true)
			if Global.cheater:
				obj.GameWinText3.text = "Run time: CHEATER!!"
			else:
				obj.GameWinText3.text = "Run time: %s" % run_time
			await obj.get_tree().create_timer(0.25).timeout
			obj.GameWinText1.visible = true
			await obj.get_tree().create_timer(1).timeout
			obj.GameWinText2.visible = true
			await obj.get_tree().create_timer(1).timeout
			obj.GameWinText3.visible = true
		else:
			obj.BattleEndText.text = "Enemy Defeated!"
			obj.BattleEndText.visible = true
		print("Hero has slain the enemy!")
	
	func force_state_change():
		return obj.Enemy.currentHealth <= 0
	
	func physics_process(_delta):
		if exit_triggered:
			return
		
		if Global.current_level < 5:
			if seconds_active >= STATE_TIME:
				exit_triggered = true
				obj.level_success()
		else:
			if Input.is_action_just_pressed("ui_accept"):
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
		Global.cheater = true
		level_success()


func level_success() -> void:
	if Global.current_level < 5:
		Global.current_level += 1
		Audio.play_overworld()
		Scenes.change(Scenes.Enum.Overworld)
	else:
		Scenes.change(Scenes.Enum.Title)

func level_fail() -> void:
	Global.reset_game()


func _on_apply_damage_to_enemy(amount: int):
	if amount > 0:
		Enemy.apply_damage(amount)
	
	
func _on_apply_damage_to_hero(amount: int):
	if amount > 0:
		if !first_hero_damage_taken:
			first_hero_damage_taken = true
			if Global.active_relics[Global.Relics.FirstDamageHalved]:
				amount = ceil(amount / 2)
		Hero.apply_damage(amount)
