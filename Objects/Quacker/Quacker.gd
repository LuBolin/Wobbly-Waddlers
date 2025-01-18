class_name Quacker
extends Node2D

signal started_moving(own_position, anim_duration)

static var QuackerScene = load("res://Objects/Quacker/Quacker.tscn")
static var DucklingScene = load("res://Objects/Quacker/Duckling.tscn")

static var quacker_instance: Quacker = null

@onready var sprite: Sprite2D = $Sprite

var children_count

var tail: Node2D

static func summonQuacker():
	var quacker = QuackerScene.instantiate()
	if not quacker_instance:
		quacker_instance = quacker
	quacker.tail = quacker
	return quacker

func addDuckling():
	var duckling = Duckling.summonDuckling(tail)
	duckling.global_position = tail.global_position
	tail = duckling
	var parent = get_parent()
	get_parent().add_child.call_deferred(duckling)
	assert(get_parent() is LevelManager)
	if get_parent() is LevelManager:
		get_parent().ducklings.append(duckling)

func move(target: Vector2, anim_duration: float):
	var need_to_rotate = tweenRotation(target, anim_duration/2.0)
	var translation_tween_duration = anim_duration
	var wait_time = 0
	if need_to_rotate:
		translation_tween_duration /= 2.0
		wait_time = translation_tween_duration
	get_tree().create_timer(wait_time).timeout.connect(
		func(): tweenToTarget(target, translation_tween_duration)
	)
	started_moving.emit(self.position, anim_duration)
	return true

func tweenRotation(target_position, tween_duration):
	var offset: Vector2 = target_position - self.global_position
	var target_rotation = offset.angle()
	var current_rotation: float = self.rotation
	var delta_rotation: float = target_rotation - current_rotation
	delta_rotation = wrapf(delta_rotation, -PI, PI)
	
	if is_zero_approx(delta_rotation):
		return false
	
	var rotationTween = get_tree().create_tween()
	rotationTween.tween_property(
		self,
		"rotation",
		current_rotation + delta_rotation,
		tween_duration
	)
	rotationTween.set_trans(Tween.TRANS_LINEAR)
	rotationTween.set_ease(Tween.EASE_OUT)
	return true

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
