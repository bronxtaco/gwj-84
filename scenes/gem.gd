extends RigidBody2D

@export var gemType : Global.GemType = Global.GemType.Blue

@export var blueGemTexture : CompressedTexture2D
@export var orangeGemTexture : CompressedTexture2D
@export var redGemTexture : CompressedTexture2D

func setup_gem(type: Global.GemType, gemPos: Vector2):
	gemType = type
	position = gemPos
	
	if gemType == Global.GemType.Blue:
		%Sprite.texture = blueGemTexture
	elif gemType == Global.GemType.Orange:
		%Sprite.texture = orangeGemTexture
	elif gemType == Global.GemType.Red:
		%Sprite.texture = redGemTexture
