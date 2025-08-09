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

@onready var AnimatedSprite : AnimatedSprite2D = $HeroSprite
@onready var HealthBar : TextureProgressBar = $HealthBar

@onready var FireBall : AnimatedSprite2D = $FireBallOrigin/FireBall

func _ready():
	reset()

var fireballActive = false

func _process(delta: float):
	if in_pre_attack():
		preAttackTimeLeft -= delta
	elif is_attacking():
		isAttacking = AnimatedSprite.is_playing()
		if !isAttacking: # TODO: This fireball is way to late. Maybe move to animation player in the future
			FireBall.play("default")
			fireballActive = true
			
	if FireBall.is_playing():
		FireBall.translate(Vector2(80.0*delta, 0.0))
	else:
		FireBall.transform.origin = Vector2(0.0, 0.0)
		if fireballActive: # TODO: remove this and replace with a new state handled by the combat scene and called into hero.gd
			Events.emit_signal("apply_damage_to_enemy")
			fireballActive = false 

func start_pre_attack(preAttackTimeTotal: float):
	preAttackTimeLeft = preAttackTimeTotal
	Events.emit_signal("enter_hero_pre_attack")
	
func start_attack():
	isAttacking = true
	AnimatedSprite.play("attack_1")
	Events.emit_signal("enter_hero_attack")

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
	return preAttackTimeLeft > 0.0

func is_attacking() -> bool:
	return isAttacking
	
