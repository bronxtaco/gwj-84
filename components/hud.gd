extends CanvasLayer

@onready var relics = [
	%Relic1,
	%Relic2,
	%Relic3,
	%Relic4,
	%Relic5,
	%Relic6,
	%Relic7,
	%Relic8,
	%Relic9,
	%Relic10,
]

func _ready() -> void:
	Events.relic_pickup.connect(_on_relic_pickup)
	refresh()


func refresh():
	for r in relics:
		r.visible = false
	for i in range(10):
		if i > Global.relic_pickup_order.size()-1:
			break
		var r_type = Global.relic_pickup_order[i]
		var r = relics[i]
		r.texture = Global.RelicTextures[r_type]
		r.visible = true


func _on_relic_pickup(_relic_type):
	refresh()
