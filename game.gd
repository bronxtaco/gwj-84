extends Node2D

func _ready() -> void:
	Events.change_scene.connect(on_change_scene)
	
	DisplayServer.window_set_size(Vector2i(1600, 1200))
	get_window().move_to_center()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if !Global.paused:
			Events.menu_push.emit(Global.MENU_TYPE.PAUSE)

func on_change_scene(new_scene:PackedScene):

	%ActiveScene.process_mode = Node.PROCESS_MODE_DISABLED

	var fade_time = 0.4
	var fade_tween = create_tween()
	fade_tween.tween_property(%Fade, "color:a", 1.0, fade_time)
	await fade_tween.finished

	for child in %ActiveScene.get_children():
		%ActiveScene.remove_child(child)
		child.queue_free()

	var new_scene_inst = new_scene.instantiate()
	%ActiveScene.add_child(new_scene_inst)

	fade_tween = create_tween()
	fade_tween.tween_property(%Fade, "color:a", 0.0, fade_time)
	await fade_tween.finished
	%ActiveScene.process_mode = Node.PROCESS_MODE_INHERIT
