extends BaseMenu

func _ready() -> void:
	Audio.play_relic_pickup()
	%RelicTexture.texture = Global.RelicTextures[Global.recent_relic_pickup]
	%RelicName.text = Global.RelicNames[Global.recent_relic_pickup]
	%RelicDescription.text = Global.RelicDescriptions[Global.recent_relic_pickup]
