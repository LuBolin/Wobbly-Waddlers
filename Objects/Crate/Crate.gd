class_name Crate
extends Node2D

static var CrateScene = load("res://Objects/Crate/Crate.tscn")

@onready var sprite: Sprite2D = $Sprite2D

var movementTween
var tween_duration = 0.1

static func summonCrate():
	var crate = CrateScene.instantiate()
	return crate
	
func move(target: Vector2):
	tweenToTarget(target, Global.TICK_DURATION)

func tweenToTarget(target_position: Vector2, duration: float):
	var movementTween = get_tree().create_tween()
	movementTween.tween_property(
		self,
		"global_position",
		target_position,
		duration
	)
	movementTween.set_trans(Tween.TRANS_LINEAR)
	movementTween.set_ease(Tween.EASE_OUT)
