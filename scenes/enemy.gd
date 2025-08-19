extends Node2D

var debug_low_health := false

@export var maxHealth : int = 100
@export var base_attack : int = 80
@export var base_attack_time : float = 45.0

@onready var Sprite := %Sprite
@onready var FireballAttack := %FireballAttack
@onready var HealthBar := $HealthBar
@onready var AttackSound := %AttackSound
@onready var DeathSound := %DeathSound

var debug_speed_up := false

var currentHealth : int:
	set(new_health):
		currentHealth = max(new_health, 0)
		HealthBar.update_health_bar(currentHealth, maxHealth)

#StateMachine
enum STATE {
	Idle,
	PreAttack,
	Attacking,
	Hurt,
	Dead,
}
var fsm := FSM.StateMachine.new(STATE, STATE.Idle, self, "Enemy")

class IdleState extends FSM.State:
	func on_enter(_prev_state):
		obj.Sprite.play("idle")


class PreAttackState extends FSM.State:
	const STATE_TIME := 0.2
	
	func on_enter(_prev_state):
		obj.Sprite.play("attack")
	
	func get_next_state():
		if seconds_active > STATE_TIME:
			return STATE.Attacking


class AttackingState extends FSM.State:
	var remaining_attack_time : float
	var base_progress := 0.0
	var tracked_time := 0.0
	var done := false
	var attack_time_modified := false
	
	func on_enter(_prev_state):
		done = false
		attack_time_modified = false
		remaining_attack_time = obj.base_attack_time * Global.SlowerAttacksMod if Global.active_relics[Global.Relics.SlowerAttacks] else obj.base_attack_time
		base_progress = 0.0
		tracked_time = 0.0
		obj.debug_speed_up = false
		obj.AttackSound.play()
		var base_damage = (ceil(obj.base_attack * 0.75)) if Global.active_relics[Global.Relics.EnemyAttackDecrease] else obj.base_attack
		obj.FireballAttack.launch_new(base_damage)
	
	func get_next_state():
		if done:
			return STATE.Idle
	
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
		
		if !attack_time_modified and obj.debug_speed_up:
			Global.cheater = true
			mod_time_fn.call(2.0)

		tracked_time += delta
		var progress_seconds = min(tracked_time, remaining_attack_time)
		var progress_normalized = min(base_progress + (progress_seconds / remaining_attack_time), 1.0)
		if obj.FireballAttack.update_progress(progress_normalized):
			done = true
			Events.apply_damage_to_hero.emit(obj.FireballAttack.damage)


class HurtState extends FSM.State:
	const STATE_TIME: float = 0.3
	func on_enter(_prev_state):
		obj.Sprite.play("hurt")
	
	func get_next_state():
		if seconds_active > STATE_TIME:
			return STATE.Idle


class DeadState extends FSM.State:
	func on_enter(_prev_state):
		print("Enemy Died!")
		obj.Sprite.play("death")
		obj.DeathSound.play()
	
	func force_state_change():
		return obj.currentHealth <= 0


func _ready():
	fsm.debug = true # enables logging for state changes
	fsm.register_state(STATE.Idle, IdleState)
	fsm.register_state(STATE.PreAttack, PreAttackState)
	fsm.register_state(STATE.Attacking, AttackingState)
	fsm.register_state(STATE.Hurt, HurtState)
	fsm.register_state(STATE.Dead, DeadState)
	
	if Global.active_relics[Global.Relics.EnemyHealthDecrease]:
		maxHealth = ceil(maxHealth * 0.75)
	
	if debug_low_health:
		currentHealth = 10
	else:
		currentHealth = maxHealth
	
	HealthBar.update_health_bar(currentHealth, maxHealth)


func _physics_process(delta: float) -> void:
	debug_speed_up = Input.is_action_pressed("debug_f1")
	fsm.physics_process(delta)


func is_idle() -> bool:
	return fsm.current_state == STATE.Idle

func start_attack() -> void:
	fsm.force_change(STATE.PreAttack)

func apply_damage(damageValue: int):
	if fsm.current_state == STATE.Dead:
		return
	
	var prevHealth = currentHealth
	currentHealth -= damageValue
	print("%d damage to enemy. Health: %d -> %d" % [ damageValue, prevHealth, currentHealth ])
	
	if currentHealth > 0:
		%HurtSound.play()
		fsm.force_change(STATE.Hurt)
	
	%HealthBar.add_damage_effect(damageValue)
