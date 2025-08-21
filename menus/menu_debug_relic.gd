extends BaseMenu

func _ready() -> void:
	%Relic1.set_pressed_no_signal(Global.active_relics[Global.Relics.MoveSpeed])
	%Relic2.set_pressed_no_signal(Global.active_relics[Global.Relics.GemRankHigherChance])
	%Relic3.set_pressed_no_signal(Global.active_relics[Global.Relics.GemNoLowestRank])
	%Relic4.set_pressed_no_signal(Global.active_relics[Global.Relics.HealPostBattle])
	%Relic5.set_pressed_no_signal(Global.active_relics[Global.Relics.HealingGemChance])
	%Relic6.set_pressed_no_signal(Global.active_relics[Global.Relics.IncreaseHeroMaxHealth])
	%Relic7.set_pressed_no_signal(Global.active_relics[Global.Relics.AttackDamageIncrease])
	%Relic8.set_pressed_no_signal(Global.active_relics[Global.Relics.EnemyAttackDecrease])
	%Relic9.set_pressed_no_signal(Global.active_relics[Global.Relics.EnemyHealthDecrease])
	%Relic10.set_pressed_no_signal(Global.active_relics[Global.Relics.IncreaseGemSpawnRate])
	%Relic11.set_pressed_no_signal(Global.active_relics[Global.Relics.IncreaseGemSpawnMax])
	%Relic12.set_pressed_no_signal(Global.active_relics[Global.Relics.WeakerObstacles])
	%Relic13.set_pressed_no_signal(Global.active_relics[Global.Relics.SlowerAttacks])
	%Relic14.set_pressed_no_signal(Global.active_relics[Global.Relics.FirstDamageHalved])
	%Relic15.set_pressed_no_signal(Global.active_relics[Global.Relics.MoreObstacles])
	%Relic16.set_pressed_no_signal(Global.active_relics[Global.Relics.ObstaclesDropHealthGems])
	%Relic17.set_pressed_no_signal(Global.active_relics[Global.Relics.ObstacleBreakAttackPause])
	%Relic18.set_pressed_no_signal(Global.active_relics[Global.Relics.GlassCannon])


func _process(delta: float) -> void:
	if Global.paused and (Input.is_action_just_pressed("debug_f7") or Input.is_action_just_pressed("ui_cancel")):
		Events.menu_unpaused.emit()
		Events.menu_pop.emit()
	
func toggle_relic(relic_type: Global.Relics, toggled_on: bool) -> void:
	if Global.active_relics[relic_type]:
		Global.drop_relic(relic_type)
	else:
		Global.pickup_relic(relic_type, true)


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
	toggle_relic(Global.Relics.IncreaseHeroMaxHealth, toggled_on)


func _on_relic_7_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.AttackDamageIncrease, toggled_on)


func _on_relic_8_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.EnemyAttackDecrease, toggled_on)


func _on_relic_9_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.EnemyHealthDecrease, toggled_on)


func _on_relic_10_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.IncreaseGemSpawnRate, toggled_on)


func _on_relic_11_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.IncreaseGemSpawnMax, toggled_on)


func _on_relic_12_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.WeakerObstacles, toggled_on)


func _on_relic_13_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.SlowerAttacks, toggled_on)


func _on_relic_14_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.FirstDamageHalved, toggled_on)


func _on_relic_15_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.MoreObstacles, toggled_on)


func _on_relic_16_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.ObstaclesDropHealthGems, toggled_on)


func _on_relic_17_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.ObstacleBreakAttackPause, toggled_on)


func _on_relic_18_toggled(toggled_on: bool) -> void:
	toggle_relic(Global.Relics.GlassCannon, toggled_on)
