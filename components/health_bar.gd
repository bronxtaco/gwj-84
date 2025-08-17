extends Node2D

func update_health_bar(current_health, max_health) -> void:
	var healthNormalized = float(current_health) / max_health
	%HealthBar.value = healthNormalized
	%HealthText.text = "%d / %d" % [ current_health, max_health ]


func add_health_effect(amount: int):
	var clone_text = %HealthText.duplicate()
	clone_text.text = "+%d" % amount
	clone_text.add_theme_font_size_override("font_size", 28)
	clone_text.add_theme_color_override("font_color", Color.GREEN)
	add_child(clone_text)
	var tween = create_tween()
	tween.tween_property(clone_text, "position:y", clone_text.position.y - 60, 0.8)
	tween.set_parallel(true).tween_property(clone_text, "modulate:a", 0.0, 0.8)
	await tween.finished
	clone_text.queue_free()


func add_damage_effect(amount: int):
	var clone_text = %HealthText.duplicate()
	clone_text.text = "-%d" % amount
	clone_text.add_theme_font_size_override("font_size", 28)
	clone_text.add_theme_color_override("font_color", Color.RED)
	add_child(clone_text)
	var tween = create_tween()
	tween.tween_property(clone_text, "position:y", clone_text.position.y - 60, 0.8)
	tween.set_parallel(true).tween_property(clone_text, "modulate:a", 0.0, 0.8)
	await tween.finished
	clone_text.queue_free()
