extends Area2D

@export var sequence: int = 0
var relic_type: Global.Relics
var active := true

func _ready() -> void:
	relic_type = Global.overworld_relics[sequence].type
	%Sprite.texture = Global.RelicTextures[relic_type]
	if !Global.overworld_relics[sequence].active:
		deactivate()

func deactivate() -> void:
	visible = false
	active = false
	Global.overworld_relics[sequence].active = false

func activate() -> void:
	visible = true
	active = true
	Global.overworld_relics[sequence].active = true
	
	'''var orig_pos = position
	var tween = create_tween()
	tween.tween_property(self, "position:y", orig_pos.y+5, 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.set_parallel().tween_property(self, "position:x", orig_pos.x+5, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(false).tween_property(self, "position:x", orig_pos.x, 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.set_parallel().tween_property(self, "position:y", orig_pos.y, 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).set_delay(1.0)
	tween.set_loops()'''
