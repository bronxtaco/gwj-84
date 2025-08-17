extends BaseMenu

func _ready() -> void:
	%Relic1.button_pressed = Global.active_relics[Global.Relics.MoveSpeed]
	%Relic2.button_pressed = Global.active_relics[Global.Relics.GemRankHigherChance]
	%Relic3.button_pressed = Global.active_relics[Global.Relics.GemNoLowestRank]
	%Relic4.button_pressed = Global.active_relics[Global.Relics.HealPostBattle]
	%Relic5.button_pressed = Global.active_relics[Global.Relics.HealingGemChance]
	%Relic6.button_pressed = Global.active_relics[Global.Relics.HealFullOneOff]
	%Relic7.button_pressed = Global.active_relics[Global.Relics.AttackDamageIncrease]
	%Relic8.button_pressed = Global.active_relics[Global.Relics.EnemyAttackDecrease]
	%Relic9.button_pressed = Global.active_relics[Global.Relics.EnemyHealthDecrease]
	%Relic10.button_pressed = Global.active_relics[Global.Relics.IncreaseGemSpawnRate]
	
func toggle_relic(relic_type: Global.Relics, toggled_on: bool) -> void:
	Global.degug_relic(relic_type, toggled_on)


func _on_relic_1_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.MoveSpeed, toggled_on)


func _on_relic_2_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.GemRankHigherChance, toggled_on)


func _on_relic_3_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.GemNoLowestRank, toggled_on)


func _on_relic_4_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.HealPostBattle, toggled_on)


func _on_relic_5_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.HealingGemChance, toggled_on)


func _on_relic_6_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.HealFullOneOff, toggled_on)


func _on_relic_7_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.AttackDamageIncrease, toggled_on)


func _on_relic_8_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.EnemyAttackDecrease, toggled_on)


func _on_relic_9_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.EnemyHealthDecrease, toggled_on)


func _on_relic_10_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.IncreaseGemSpawnRate, toggled_on)
