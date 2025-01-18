class_name Blood
extends Sprite2D

static var BloodScene = load("res://Objects/Blood.tscn")

static func summonBlood():
	var blood = BloodScene.instantiate()
	return blood

func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(
		func(): self.queue_free()
	)
