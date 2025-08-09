extends Node2D

@export var maxHealth : int = 100

var currentHealth : int = maxHealth;

var isDead : bool = false
var isAttacking : bool = false; # TODO: thought here is I can track wait until an anim is ended
var preAttackTimeLeft : float = 0.0

func reset():
	isDead = false
	isAttacking = false
	preAttackTimeLeft = 0.0
	set_health(maxHealth)

@onready var AnimatedSprite : AnimatedSprite2D = $EnemySprite
@onready var HealthBar : TextureProgressBar = $HealthBar

func _ready():
	reset()

func _process(delta: float):
	if in_pre_attack():
		preAttackTimeLeft -= delta
	elif is_attacking():
		isAttacking = AnimatedSprite.is_playing()

func start_pre_attack(preAttackTimeTotal: float):
	preAttackTimeLeft = preAttackTimeTotal
	Events.emit_signal("enter_enemy_pre_attack")

func start_attack():
	isAttacking = true
	AnimatedSprite.play("attack")
	Events.emit_signal("enter_enemy_attack")

func apply_damage(damageValue: int):
	if isDead: return
	
	var prevHealth = currentHealth
	var newHealth = max(currentHealth - damageValue, 0);
	set_health(newHealth)
	
	print("%d damage to enemy. Health: %d -> %d" % [damageValue, prevHealth, newHealth])

func set_health(healthValue: int):
	currentHealth = max(healthValue, 0)
	
	var healthNormalized = float(currentHealth) / maxHealth
	HealthBar.value = healthNormalized;
	
	# check if dead
	if !isDead && currentHealth <= 0:
		isDead = true
		print("Enemy Died!")
		Events.emit_signal("enemy_died")

func in_pre_attack() -> bool:
	return preAttackTimeLeft > 0.0

func is_attacking() -> bool:
	return isAttacking
