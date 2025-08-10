extends Node2D

@export var preAttackTimeTotal: float = 4.0

@export var attackDamageDefault: int = 20

@onready var Hero = $Hero
@onready var Enemy = $Enemy

enum CombatState {
	Uninitialized = 0,
	HeroPreAttack,
	HeroAttack,
	EnemyPreAttack,
	EnemyAttack,
}
var combatState : CombatState = CombatState.Uninitialized

var nextEnemyAttackDamage : int = attackDamageDefault

func reset():
	setState(CombatState.HeroPreAttack)
	nextEnemyAttackDamage = attackDamageDefault

func _ready():
	Events.apply_damage_to_enemy.connect(_on_apply_damage_to_enemy)
	Events.apply_damage_to_hero.connect(_on_apply_damage_to_hero)
	
	set_random_background()
	reset()

func _process(delta: float):
	if combatState == CombatState.HeroPreAttack:
		if !Hero.in_pre_attack():
			setState(CombatState.HeroAttack)
	elif combatState == CombatState.HeroAttack:
		if !Hero.is_attacking():
			setState(CombatState.EnemyPreAttack)
	elif combatState == CombatState.EnemyPreAttack:
		if !Enemy.in_pre_attack():
			setState(CombatState.EnemyAttack)
	elif combatState == CombatState.EnemyAttack:
		if !Enemy.is_attacking():
			setState(CombatState.HeroPreAttack)


func set_random_background():
	var randomBackgroudPath = "res://assets/combat/backgrounds/game_background_%d.png" % (randi() % 8 + 1)
	%RandomBackground.texture = load(randomBackgroudPath)


func setState(newState: CombatState):
	if newState == combatState: return
	
	match(newState):
		CombatState.HeroPreAttack:
			Hero.start_pre_attack(preAttackTimeTotal)
		CombatState.HeroAttack:
			Hero.start_attack()
			# debug crit boosts for testing, these will be fired off from the actual game bit when the player makes progress
			var crit = func(_amount):
				Events.hero_crit_boost.emit(_amount)
			create_tween().tween_callback(crit.bind(5)).set_delay(3.0)
			create_tween().tween_callback(crit.bind(15)).set_delay(6.0)
			create_tween().tween_callback(crit.bind(25)).set_delay(9.0)
		
		CombatState.EnemyPreAttack:
			Enemy.start_pre_attack(preAttackTimeTotal)
		CombatState.EnemyAttack:
			Enemy.start_attack()
	
	combatState = newState
	print("Enter %s combat state" % CombatState.keys()[combatState])

func hero_attack_enemy(damageAmount: int):
	Hero.apply_damage(damageAmount)

func enemy_attack_hero(damageAmount: int):
	Enemy.apply_damage(damageAmount)

func _on_apply_damage_to_enemy(amount: int):
	Enemy.apply_damage(amount)
	
func _on_apply_damage_to_hero():
	Enemy.apply_damage(nextEnemyAttackDamage)
