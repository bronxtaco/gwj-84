extends Path2D

var crit_boost_scene = preload("res://components/crit_boost.tscn")

var staff_pos: Vector2

var size := 1:
	set(_size):
		size = _size
		%Fireball.play("size_%d" % size)
		%FireballTrail.emission_sphere_radius = 5.0 + (3 * size)

var damage: int = 10:
	set(_damage):
		if _damage == 10:
			size = 1
		else:
			size = min(size + 1, 5)
		damage = _damage
		%DamageText.text = str(damage)
		

func _ready() -> void:
	Events.hero_crit_boost.connect(_on_hero_crit_boost)
	%DamageText.text = str(damage)

func set_staff_pos(pos: Vector2):
	staff_pos = pos

func get_fireball_pos():
	return %FireballMarker.global_position

func reset_damage():
	size = 1
	damage = 10

func explode():
	%Fireball.play("explode")
	Events.fireball_exploded.emit()

func _on_hero_crit_boost(boost_amount: int) -> void:
	var crit_boost = crit_boost_scene.instantiate()
	get_parent().add_child(crit_boost)
	crit_boost.global_position = staff_pos
	
	var deferred_fn = func():
		crit_boost.start(%FireballMarker.global_position)
		await get_tree().create_timer(crit_boost.travel_time).timeout
	
		damage += boost_amount
		var boost_text = %DamageText.duplicate()
		boost_text.text = "+%d" % boost_amount
		boost_text.add_theme_font_size_override("font_size", 12)
		%DamageText.get_parent().add_child(boost_text)
		var tween = create_tween()
		tween.tween_property(boost_text, "position:y", boost_text.position.y - 20, 0.3)
		tween.set_parallel(true).tween_property(boost_text, "modulate:a", 0.0, 0.3)
		await tween.finished
		boost_text.queue_free()
		crit_boost.queue_free()
	
	deferred_fn.call_deferred()

func _on_fireball_animation_finished() -> void:
	self.visible = false
