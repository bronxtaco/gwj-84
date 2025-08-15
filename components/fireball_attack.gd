extends Path2D

@export var gets_boosted := true # true for player fireball, false for enemy. might change this later depending on minigame design

const SizeTable = [ # size = index where damage less than value
	0, # damage can't be zero so size can't be zero
	25, # size: 1
	50, # size: 2
	100, # size: 3
	150, # size: 4
	999999999, # size: 5
]

var crit_boost_scene = preload("res://components/crit_boost.tscn")

var active := false

var size := 1:
	set(_size):
		size = _size
		%Fireball.play("size_%d" % size)
		%FireballTrail.emission_sphere_radius = 5.0 + (3 * size)

var damage: int = 10:
	set(_damage):
		damage = _damage
		size = get_size_from_damage(damage)
		%DamageText.text = str(damage)
		

func _ready() -> void:
	Events.crit_boost.connect(_on_crit_boost)
	%DamageText.text = str(damage)


func get_fireball_pos():
	return %FireballMarker.global_position

func launch_new(damage_: int):
	visible = true
	active = true
	damage = damage_


func get_size_from_damage(damage):
	var size
	for i in range(SizeTable.size()):
		size = i
		if damage <= SizeTable[i]:
			break
	return size
	
func explode():
	active = false
	%Fireball.play("explode")
	Events.fireball_exploded.emit()

func _on_crit_boost(gem_type: Global.GemType, boost_amount: int) -> void:
	if !active:
		return
	
	var mod_prefix = "+"
	if !gets_boosted:
		mod_prefix = "-"
		boost_amount *= -1
	
	var crit_boost = crit_boost_scene.instantiate()
	crit_boost.initialize(gem_type)
	get_parent().add_child(crit_boost)
	crit_boost.global_position = Global.staff_pos
	
	var deferred_fn = func():
		crit_boost.start(%FireballMarker.global_position)
		await get_tree().create_timer(crit_boost.travel_time).timeout
		crit_boost.queue_free()
		
		if active:
			damage += boost_amount
			var boost_text = %DamageText.duplicate()
			boost_text.text = "%s%d" % [ mod_prefix, boost_amount ]
			boost_text.add_theme_font_size_override("font_size", 12)
			%DamageText.get_parent().add_child(boost_text)
			var tween = create_tween()
			tween.tween_property(boost_text, "position:y", boost_text.position.y - 20, 0.3)
			tween.set_parallel(true).tween_property(boost_text, "modulate:a", 0.0, 0.3)
			await tween.finished
			boost_text.queue_free()
	
	deferred_fn.call_deferred()

func _on_fireball_animation_finished() -> void:
	visible = false
