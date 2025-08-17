extends Node2D

@onready var Sprite := %Sprite
@onready var AttackSound := %AttackSound
@onready var FireballAttack := %FireballAttack
@onready var HealthBar := $HealthBar

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
	const STATE_TIME: float = 30.0
	var done := false
	
	func get_next_state():
		if done:
			return STATE.Idle

	func on_enter(_prev_state):
		done = false
		obj.Sprite.play("attack_loop")
		obj.AttackSound.play()
		obj.FireballAttack.launch_new(10)
	
	func physics_process(_delta):
		if done:
			return
		
		var progress_seconds = min(seconds_active, STATE_TIME)
		var progress_normalized = progress_seconds / STATE_TIME
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
	
	func force_state_change():
		return Global.hero_health <= 0


class VictoryState extends FSM.State:
	func on_enter(_prev_state):
		obj.Sprite.play("victory")


func _ready():
	Events.crit_boost.connect(_on_crit_boost)
	
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
	fsm.physics_process(delta)
	
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
	var newHealth = max(prevHealth - damageValue, 0);
	Global.hero_health = newHealth
	
	print("%d damage to hero. Health: %d -> %d" % [ damageValue, prevHealth, newHealth ])
	
	update_health_bar()
	
	if newHealth > 0:
		fsm.force_change(STATE.Hurt)

func update_health_bar() -> void:
	var healthNormalized = float(Global.hero_health) / Global.HERO_HEALTH
	HealthBar.value = healthNormalized


func _on_crit_boost(_gem_type: Global.GemType, boost_amount: int) -> void:
	if fsm.current_state == STATE.Attacking:
		Sprite.play("attack_boost")
	elif fsm.current_state == STATE.Idle: # defence
		Sprite.play("defence_boost")


func _on_sprite_animation_finished() -> void:
	if fsm.current_state == STATE.Attacking:
		Sprite.play("attack_loop")
	elif fsm.current_state == STATE.Idle: # defence
		Sprite.play("idle")
	elif fsm.current_state == STATE.Dead:
		Sprite.visible = false
		%Shadow.visible = false
		
