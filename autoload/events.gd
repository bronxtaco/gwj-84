extends Node
@warning_ignore_start("unused_signal")

signal change_scene(new_scene:PackedScene)

signal menu_push(menu: Global.MENU_TYPE, data: Dictionary)
signal menu_pop
signal menu_pop_all
signal menu_empty

signal apply_damage_to_enemy
signal apply_damage_to_hero

signal hero_died
signal enemy_died

signal enter_hero_pre_attack
signal enter_hero_attack

signal enter_enemy_pre_attack
signal enter_enemy_attack
