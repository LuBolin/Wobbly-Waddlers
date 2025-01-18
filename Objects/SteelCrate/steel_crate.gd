class_name SteelCrate
extends Node2D

static var CrateScene = load("res://Objects/SteelCrate/SteelCrate.tscn")

@onready var sprite: Sprite2D = $Sprite2D

static func summonSteelCrate():
	var crate = CrateScene.instantiate()
	return crate
