class_name Egg
extends Node2D

static var EggScene = load("res://Objects/Egg/Egg.tscn")

@onready var sprite: Sprite2D = $Sprite

static func summonEgg():
	var egg = EggScene.instantiate()
	return egg

func hatch():
	if Quacker.quacker_instance:
		Quacker.quacker_instance.addDuckling()
	queue_free()

func die():
	queue_free()
	Singleton.lose.emit()
