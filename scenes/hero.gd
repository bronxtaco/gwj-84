extends Node2D

const ATTACK_TIME : float = 15.0 # TODO: different attack options could have different times?

@export var maxHealth : int = 100

var currentHealth : int = maxHealth;

var isDead : bool = false
var isInPreAttack : bool = false
var isAttacking : bool = false; # TODO: thought here is I can track wait until an anim is ended
#var preAttackTimeLeft : float = 0.0
var attackTimeLeft : float = ATTACK_TIME

func reset():
	%HeroSprite.play("default")
	isDead = false
	isInPreAttack = false
	isAttacking = false
	set_health(maxHealth)

@onready var AnimatedSprite : AnimatedSprite2D = $HeroSprite
@onready var HealthBar : TextureProgressBar = $HealthBar

func _ready():
	reset()

func _process(delta: float):
	if is_attacking():
		attackTimeLeft = max(attackTimeLeft - delta, 0)
		for pathFollow in %FireballAttack.get_children():
			pathFollow.progress_ratio = 1 - (attackTimeLeft / ATTACK_TIME)
		isAttacking = attackTimeLeft > 0
		if !isAttacking:
			%FireballAttack.visible = false
			Events.apply_damage_to_enemy.emit(%FireballAttack.damage)


func start_pre_attack(preAttackTimeTotal: float):
	isInPreAttack = true
	%HeroSprite.play("attack_1")


func start_attack():
	isAttacking = true
	attackTimeLeft = ATTACK_TIME
	%FireballAttack.reset_damage()
	%FireballAttack.visible = true

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
	return %HeroSprite.animation == &"attack_1" and %HeroSprite.frame < 4 # fire on frame 4


func is_attacking() -> bool:
	return isAttacking
	

func _on_hero_sprite_animation_finished() -> void:
	%HeroSprite.play("default")
