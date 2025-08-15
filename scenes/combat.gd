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
@onready var Enemy = $Enemy

# StateMachine
enum STATE {
	Idle,
	HeroAttack,
	HeroDefence,
}
var fsm := FSM.StateMachine.new(STATE, STATE.Idle, self, "Combat")

class IdleState extends FSM.State:
	const STATE_TIME := 3.0 # the downtime between attacks
	var next_state: STATE
	
	func get_next_state():
		if seconds_active > STATE_TIME:
			return next_state

	func on_enter(prev_state):
		next_state = STATE.HeroAttack # hero always attacks first
		if prev_state != null:        # and then alternates
			next_state = STATE.HeroAttack if prev_state == STATE.HeroDefence else STATE.HeroDefence

class HeroAttackState extends FSM.State:
	func get_next_state():
		if obj.Hero.is_idle():
			return STATE.Idle

	func on_enter(prev_state):
		obj.Hero.start_attack()

class HeroDefenceState extends FSM.State:
	func get_next_state():
		if seconds_active > 2.0:
			return STATE.Idle

	func on_enter(prev_state):
		pass


func _ready():
	Events.apply_damage_to_enemy.connect(_on_apply_damage_to_enemy)
	Events.apply_damage_to_hero.connect(_on_apply_damage_to_hero)
	
	fsm.debug = true # enables logging for state changes
	fsm.register_state(STATE.Idle, IdleState)
	fsm.register_state(STATE.HeroAttack, HeroAttackState)
	fsm.register_state(STATE.HeroDefence, HeroDefenceState)
	
	%BackgroundFlipped.texture = level_bg_map[Global.current_level]
	%Background.texture = level_bg_map[Global.current_level]


func _physics_process(delta: float):
	fsm.physics_process(delta)
	
	if Input.is_action_just_pressed("debug_f6"):
		Global.current_level += 1
		Audio.play_overworld()
		Scenes.change(Scenes.Enum.Overworld)


func _on_apply_damage_to_enemy(amount: int):
	Enemy.apply_damage(amount)
	
func _on_apply_damage_to_hero(amount: int):
	Hero.apply_damage(amount)
