extends Node
@warning_ignore_start("unused_signal")

signal change_scene(new_scene:PackedScene)

signal menu_push(menu: Global.MENU_TYPE, data: Dictionary)
signal menu_pop
signal menu_pop_all
signal menu_empty
signal menu_unpaused
signal menu_enable
signal menu_disable

signal apply_damage_to_enemy(amount: int)
signal apply_damage_to_hero
signal fireball_active
signal fireball_inactive
signal pause_attack(pause_time: float)

signal crit_boost(gem_type: Global.GemType, amount: int)
signal heal_boost(amount: int)
signal hero_health_changed

signal attack_phase_begin()
signal attack_phase_end()
signal defence_phase_begin()
signal defence_phase_end()

signal spawn_combined_gem_type(gemType: Global.GemType, position_: Vector2, impulse: Vector2, useDropSpawn: bool)

signal spawn_gem_external(gem_type: Global.GemType, pos: Vector2)
signal kill_gem_scored()

signal refresh_hud()

signal draw_debug_vector_arrow(start_pos: Vector2, vector: Vector2, color: Color, thickness: float, arrow_size: float)
