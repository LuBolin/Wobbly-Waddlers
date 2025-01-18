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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
