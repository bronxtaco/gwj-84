extends Node2D

func _ready() -> void:
	Events.change_scene.connect(on_change_scene)
	
	DisplayServer.window_set_size(Vector2i(1600, 1200))
	get_window().move_to_center()
	Scenes.change(Scenes.Enum.Splash)

func _process(delta: float) -> void:
	if Scenes.is_pause_enabled() and Input.is_action_just_pressed("pause"):
		if !Global.paused:
			Events.menu_push.emit(Global.MENU_TYPE.PAUSE)
	
	if !Global.paused and Global.game_active:
		Global.total_run_time += delta
	
	if Scenes.is_current_scene_gameplay() and !Global.paused and Input.is_action_just_pressed("debug_f7"):
		Global.cheater = true
		Events.menu_push.emit(Global.MENU_TYPE.DEBUG_RELIC)

func on_change_scene(new_scene:PackedScene):
	
	%HUD.visible = Global.hud_enabled
	
	%ActiveScene.process_mode = Node.PROCESS_MODE_DISABLED

	var fade_time = 0.7
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
	Events.menu_enable.emit()
	%ActiveScene.process_mode = Node.PROCESS_MODE_INHERIT
