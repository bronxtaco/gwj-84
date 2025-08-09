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

var nextHeroAttackDamage : int = attackDamageDefault
var nextEnemyAttackDamage : int = attackDamageDefault

func reset():
	setState(CombatState.HeroPreAttack)
	nextHeroAttackDamage = attackDamageDefault # TODO: damageAmountDefault will like become randomized in a range 
	nextEnemyAttackDamage = attackDamageDefault

func _ready():
	Events.connect("apply_damage_to_enemy", Callable(self, "_on_apply_damage_to_enemy"))
	Events.connect("apply_damage_to_hero", Callable(self, "_on_apply_damage_to_hero"))
	
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
	
	debug_combat_state()

func setState(newState: CombatState):
	if newState == combatState: return
	
	match(newState):
		CombatState.HeroPreAttack:
			Hero.start_pre_attack(preAttackTimeTotal)
			DebugDamageText.text = "Upcoming Hero Damage %d" % nextHeroAttackDamage
		CombatState.HeroAttack:
			Hero.start_attack()
		CombatState.EnemyPreAttack:
			Enemy.start_pre_attack(preAttackTimeTotal)
			DebugDamageText.text = "Upcoming Enemy Damage %d" % nextEnemyAttackDamage
		CombatState.EnemyAttack:
			Enemy.start_attack()
	
	combatState = newState
	print("Enter %s combat state" % CombatState.keys()[combatState])

func hero_attack_enemy(damageAmount: int):
	Hero.apply_damage(damageAmount)

func enemy_attack_hero(damageAmount: int):
	Enemy.apply_damage(damageAmount)

func _on_apply_damage_to_enemy():
	Enemy.apply_damage(nextHeroAttackDamage)
	
func _on_apply_damage_to_hero():
	Enemy.apply_damage(nextEnemyAttackDamage)


# debug code down here
 # TODO: only for testing. Remove eventually? 
@onready var DebugDamageText = $DebugDamageText
@onready var DebugPreAttackProgress = $DebugPreAttackProgress


func debug_combat_state():
	match(combatState):
		CombatState.HeroPreAttack:
			DebugDamageText.text = "Upcoming Hero Damage %d" % nextHeroAttackDamage
			DebugPreAttackProgress.value = Hero.preAttackTimeLeft / preAttackTimeTotal
		CombatState.HeroAttack:
			DebugPreAttackProgress.value = 1.0
		CombatState.EnemyPreAttack:
			DebugDamageText.text = "Upcoming Enemy Damage %d" % nextEnemyAttackDamage
			DebugPreAttackProgress.value = Enemy.preAttackTimeLeft / preAttackTimeTotal
		CombatState.EnemyAttack:
			DebugPreAttackProgress.value = 1.0
