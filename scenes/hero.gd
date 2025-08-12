extends Node2D

const ATTACK_TIME : float = 15.0 # TODO: different attack options could have different times?

@export var maxHealth : int = 100

enum HeroState {
	Idle,
	PreAttack,
	Attacking,
}
var state := HeroState.Idle:
	set(_state):
		state = _state
		if state == HeroState.Idle:
			%HeroSprite.play("idle")
		elif state == HeroState.PreAttack:
			$PreAttackTimer.start()
		elif state == HeroState.Attacking:
			attackTimeLeft = ATTACK_TIME
			%HeroSprite.play("attack_loop")
			%FireballAttack.reset_damage()
			%FireballAttack.visible = true

var currentHealth : int = maxHealth;

var isDead : bool = false
var isIdle: bool = true
var isInPreAttack : bool = false
var isAttacking : bool = false; # TODO: thought here is I can track wait until an anim is ended
#var preAttackTimeLeft : float = 0.0
var attackTimeLeft : float = ATTACK_TIME

func reset():
	%HeroSprite.play("idle")
	isDead = false
	state = HeroState.Idle
	set_health(maxHealth)

@onready var AnimatedSprite : AnimatedSprite2D = $HeroSprite
@onready var HealthBar : TextureProgressBar = $HealthBar

func _ready():
	reset()
	%FireballAttack.set_staff_pos($StaffPos.global_position)

func _process(delta: float):
	if is_attacking():
		attackTimeLeft = max(attackTimeLeft - delta, 0)
		for pathFollow in %FireballAttack.get_children():
			pathFollow.progress_ratio = 1 - (attackTimeLeft / ATTACK_TIME)
		if attackTimeLeft <= 0:
			start_idle()
			%FireballAttack.explode()
			Events.apply_damage_to_enemy.emit(%FireballAttack.damage)


func start_idle():
	state = HeroState.Idle

func start_pre_attack():
	state = HeroState.PreAttack

func start_attack():
	state = HeroState.Attacking

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
		Events.emit_signal("hero_died")


func in_pre_attack() -> bool:
	return state == HeroState.PreAttack


func is_attacking() -> bool:
	return state == HeroState.Attacking
	

func _on_hero_sprite_animation_finished() -> void:
	if %HeroSprite.animation == &"attack_frame_1":
		state = HeroState.Attacking
	else:
		%HeroSprite.play("idle")


func _on_idle_timer_timeout() -> void:
	if state == HeroState.Idle:
		%HeroSprite.play("yawn")


func _on_pre_attack_timer_timeout() -> void:
	%HeroSprite.play("attack_frame_1")
