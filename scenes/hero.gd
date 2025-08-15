extends Node2D

@export var maxHealth : int = 100

@onready var Sprite := %Sprite
@onready var FireballAttack := %FireballAttack

var currentHealth : int = maxHealth;

var isDead : bool = false

#StateMachine
enum STATE {
	Idle,
	PreAttack,
	Attacking,
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
		obj.Sprite.play("attack_frame_1")

class AttackingState extends FSM.State:
	const STATE_TIME: float = 25.0 # TODO: different attack options could have different times?
	var done := false
	
	func get_next_state():
		if done:
			return STATE.Idle

	func on_enter(_prev_state):
		done = false
		obj.Sprite.play("attack_loop")
		obj.FireballAttack.launch_new(10)
	
	func physics_process(_delta):
		if done:
			return
		
		var progress_seconds = min(seconds_active, STATE_TIME)
		for pathFollow in obj.FireballAttack.get_children():
			pathFollow.progress_ratio = progress_seconds / STATE_TIME
		if progress_seconds == STATE_TIME:
			done = true
			obj.FireballAttack.explode()
			Events.apply_damage_to_enemy.emit(obj.FireballAttack.damage)


@onready var HealthBar : TextureProgressBar = $HealthBar

func _ready():
	fsm.debug = true # enables logging for state changes
	fsm.register_state(STATE.Idle, IdleState)
	fsm.register_state(STATE.PreAttack, PreAttackState)
	fsm.register_state(STATE.Attacking, AttackingState)
	
	Global.staff_pos = $StaffPos.global_position

func _physics_process(delta: float) -> void:
	fsm.physics_process(delta)
	
func is_idle() -> bool:
	return fsm.current_state == STATE.Idle

func start_attack() -> void:
	fsm.force_change(STATE.PreAttack)

func apply_damage(damageValue: int):
	if isDead: return
	
	var prevHealth = currentHealth
	var newHealth = max(currentHealth - damageValue, 0);
	set_health(newHealth)
	
	print("%d damage to hero. Health: %d -> %d" % [damageValue, prevHealth, newHealth])


func set_health(healthValue: int):
	currentHealth = max(healthValue, 0)
	
	var healthNormalized = float(currentHealth) / maxHealth
	HealthBar.value = healthNormalized;
	
	# check if dead
	if !isDead && currentHealth <= 0:
		isDead = true
		print("Hero Died!")


func _on_idle_timer_timeout() -> void:
	pass
	'''if state == HeroState.Idle:
		%HeroSprite.play("yawn")'''
