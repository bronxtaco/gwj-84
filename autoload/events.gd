extends Node
@warning_ignore_start("unused_signal")

signal change_scene(new_scene:PackedScene)

signal menu_push(menu: Global.MENU_TYPE, data: Dictionary)
signal menu_pop
signal menu_pop_all
signal menu_empty
signal menu_unpaused

signal apply_damage_to_enemy(amount: int)
signal apply_damage_to_hero
signal fireball_active
signal fireball_inactive

signal crit_boost(gem_type: Global.GemType, amount: int)
signal heal_boost(amount: int)

signal spawn_combined_gem_type(gemType: Global.GemType, position_: Vector2, impulse: Vector2, useDropSpawn: bool)

signal spawn_kill_gem()
signal kill_gem_scored()

signal refresh_hud()
