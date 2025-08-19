extends Node2D

@onready var Sprite := %Sprite
@onready var AttackSound := %AttackSound
@onready var DeathSound := %DeathSound
@onready var FireballAttack := %FireballAttack

#StateMachine
enum STATE {
	Idle,
	PreAttack,
	Attacking,
	Hurt,
	Dead,
	Victory,
}
var fsm := FSM.StateMachine.new(STATE, STATE.Idle, self, "Hero")

var kill_gem_speed_up := false
var debug_speed_up := false

class IdleState extends FSM.State:
	func get_next_state():
		pass # combat class decides when the hero changes out of idle

	func on_enter(_prev_state):
		obj.Sprite.play("idle")


class PreAttackState extends FSM.State:
	const STATE_TIME := 0.2
	
	func get_next_state():
		if seconds_active > STATE_TIME:
			return STATE.Attacking

	func on_enter(_prev_state):
		obj.Sprite.play("attack_intro")


class AttackingState extends FSM.State:
	const BaseAttackTime := 30.0
	var remaining_attack_time := BaseAttackTime
	var base_progress := 0.0
	var tracked_time := 0.0
	var done := false
	var attack_time_modified := false
	
	func get_next_state():
		if done:
			return STATE.Idle

	func on_enter(_prev_state):
		done = false
		attack_time_modified = false
		remaining_attack_time = BaseAttackTime * Global.SlowerAttacksMod if Global.active_relics[Global.Relics.SlowerAttacks] else BaseAttackTime
		base_progress = 0.0
		tracked_time = 0.0
		obj.debug_speed_up = false
		obj.kill_gem_speed_up = false
		obj.Sprite.play("attack_loop")
		obj.AttackSound.play()
		var base_damage = 30 if Global.active_relics[Global.Relics.AttackDamageIncrease] else 10
		obj.FireballAttack.launch_new(base_damage)
	
	func physics_process(delta):
		if done:
			return
		
		var mod_time_fn = func(abs_time_left: float):
			attack_time_modified = true
			var progress_seconds = min(seconds_active, remaining_attack_time)
			var progress_normalized = progress_seconds / remaining_attack_time
			base_progress = progress_normalized
			tracked_time = 0.0
			remaining_attack_time = abs_time_left
		
		if !attack_time_modified and obj.kill_gem_speed_up:
			mod_time_fn.call(3.0)
		elif !attack_time_modified and obj.debug_speed_up:
			mod_time_fn.call(2.0)
		
		tracked_time += delta
		var progress_seconds = min(tracked_time, remaining_attack_time)
		var progress_normalized = min(base_progress + (progress_seconds / remaining_attack_time), 1.0)
		if obj.FireballAttack.update_progress(progress_normalized):
			done = true
			Events.apply_damage_to_enemy.emit(obj.FireballAttack.damage)


class HurtState extends FSM.State:
	const STATE_TIME: float = 0.5
	func on_enter(_prev_state):
		obj.Sprite.play("hurt")
	
	func get_next_state():
		if seconds_active > STATE_TIME:
			return STATE.Idle


class DeadState extends FSM.State:
	func on_enter(_prev_state):
		print("Hero Died!")
		obj.Sprite.play("death")
		obj.DeathSound.play()
	
	func force_state_change():
		return Global.hero_health <= 0


class VictoryState extends FSM.State:
	func on_enter(_prev_state):
		obj.Sprite.play("victory")

func get_fireball_damage() -> int:
	return %FireballAttack.damage if %FireballAttack.active else 0

func _ready():
	Events.crit_boost.connect(_on_crit_boost)
	Events.heal_boost.connect(_on_heal_boost)
	Events.kill_gem_scored.connect(_on_kill_gem)
	Events.hero_health_changed.connect(_on_hero_health_changed)
	
	
	fsm.debug = true # enables logging for state changes
	fsm.register_state(STATE.Idle, IdleState)
	fsm.register_state(STATE.PreAttack, PreAttackState)
	fsm.register_state(STATE.Attacking, AttackingState)
	fsm.register_state(STATE.Hurt, HurtState)
	fsm.register_state(STATE.Dead, DeadState)
	fsm.register_state(STATE.Victory, VictoryState)
	
	update_health_bar()
	
	Global.staff_pos = $StaffPos.global_position

func _physics_process(delta: float) -> void:
	debug_speed_up = Input.is_action_just_pressed("debug_f1")
	fsm.physics_process(delta)
	
	'''if Input.is_action_just_pressed("debug_f1"):
		heal(30)
	elif Input.is_action_just_pressed("debug_f2"):
		apply_damage(50)'''
	
func is_idle() -> bool:
	return fsm.current_state == STATE.Idle

func start_attack() -> void:
	fsm.force_change(STATE.PreAttack)

func battle_victory() -> void:
	fsm.force_change(STATE.Victory)

func apply_damage(damageValue: int):
	if fsm.current_state == STATE.Dead:
		return
	
	var prevHealth = Global.hero_health
	var newHealth = max(prevHealth - damageValue, 0)
	Global.hero_health = newHealth
	
	print("%d damage to hero. Health: %d -> %d" % [ damageValue, prevHealth, newHealth ])
	
	update_health_bar()
	%HealthBar.add_damage_effect(damageValue)
	if newHealth > 0:
		%HurtSound.play()
		fsm.force_change(STATE.Hurt)

func heal(amount: int):
	var prevHealth = Global.hero_health
	var newHealth = min(prevHealth + amount, Global.hero_max_health)
	Global.hero_health = newHealth
	
	print("%d heal for hero. Health: %d -> %d" % [ amount, prevHealth, newHealth ])
	
	update_health_bar()
	%HealthBar.add_health_effect(amount)
	Audio.play_heal()


func update_health_bar() -> void:
	%HealthBar.update_health_bar(Global.hero_health, Global.hero_max_health)


func _on_crit_boost(_gem_type: Global.GemType, boost_amount: int) -> void:
	if fsm.current_state == STATE.Attacking:
		Sprite.play("attack_boost")
	elif fsm.current_state == STATE.Idle: # defence
		Sprite.play("defence_boost")


func _on_heal_boost(boost_amount: int) -> void:
	heal(boost_amount)


func _on_kill_gem():
	kill_gem_speed_up = true
	
	
func _on_sprite_animation_finished() -> void:
	if fsm.current_state == STATE.Attacking:
		Sprite.play("attack_loop")
	elif fsm.current_state == STATE.Idle: # defence
		Sprite.play("idle")
	elif fsm.current_state == STATE.Dead:
		Sprite.visible = false
		%Shadow.visible = false


func _on_hero_health_changed():
	update_health_bar()
