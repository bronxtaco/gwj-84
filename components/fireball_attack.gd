extends Path2D

@export var gets_boosted := true # true for player fireball, false for enemy. might change this later depending on minigame design
@export var explode_audio: Array[AudioStream] = []

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
var frozen := false

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


func freeze():
	frozen = true
	%FireballTrail.emitting = false
	%Fireball.pause()


func unfreeze():
	frozen = false
	%FireballTrail.emitting = true
	%Fireball.play()
	

func launch_new(damage_: int):
	%FireballPath.scale = Vector2.ONE
	visible = true
	active = true
	unfreeze()
	damage = damage_
	%LaunchSound.play()
	%TravelSound.play()
	Events.fireball_active.emit()


func update_progress(progress: float, freeze: bool) -> bool:
	if active:
		if !frozen and freeze:
			freeze()
		elif frozen and !freeze:
			unfreeze()
		for pathFollow in get_children():
			if pathFollow is PathFollow2D:
				pathFollow.progress_ratio = progress
		if progress == 1:
			explode()
	
	if !active:
		Events.fireball_inactive.emit()
	return !active


func get_size_from_damage(damage):
	var size
	for i in range(SizeTable.size()):
		size = i
		if damage <= SizeTable[i]:
			break
	return clamp(size, 1, 5)


func explode():
	active = false
	%Fireball.play("explode")
	%ExplodeSound.stream = explode_audio[size-1]
	%ExplodeSound.play()
	%TravelSound.stop()


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
			damage = max(damage + boost_amount, 0)
			if damage == 0: # attack has been neutralized
				create_tween().tween_property(%FireballPath, "scale", Vector2.ZERO, 0.8)
			var boost_text = %DamageText.duplicate()
			boost_text.text = "%s%d" % [ mod_prefix, boost_amount ]
			boost_text.add_theme_font_size_override("font_size", 12)
			%DamageText.get_parent().add_child(boost_text)
			var tween = create_tween()
			tween.tween_property(boost_text, "position:y", boost_text.position.y - 20, 0.3)
			tween.set_parallel(true).tween_property(boost_text, "modulate:a", 0.0, 0.3)
			await tween.finished
			boost_text.queue_free()
			
			await get_tree().create_timer(0.5).timeout
			if damage == 0:
				active = false # attack has been neutralized
				visible = false
	
	deferred_fn.call_deferred()

func _on_fireball_animation_finished() -> void:
	visible = false
