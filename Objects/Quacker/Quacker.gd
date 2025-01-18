class_name Quacker
extends Node2D

static var QuackerScene = load("res://Objects/Quacker/Quacker.tscn")

@onready var sprite: Sprite2D = $Sprite

var movementTween
var tween_duration = 0.1

static func summonQuacker():
	var quacker = QuackerScene.instantiate()
	return quacker
	
func move(target: Vector2):
	tweenToTarget(target, tween_duration)
	return true

func tweenToTarget(target_position: Vector2, duration: float):
	movementTween = get_tree().create_tween()
	movementTween.tween_property(
		self,
		"global_position",
		target_position,
		duration
	)
	movementTween.set_trans(Tween.TRANS_LINEAR)
	movementTween.set_ease(Tween.EASE_OUT)
