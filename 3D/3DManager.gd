extends Node3D

const lvlFileName = "res://Levels/Level"

@export_range(-5, 5) var stand_x_offset: float

func _ready():
	# initialise stand, where the tip is at y = 0
	var standCapsule: CapsuleShape3D = $Stand/StandCollider.shape
	%Stand.position = Vector3(stand_x_offset, -standCapsule.height/2.0 + standCapsule.radius, 0)
	var boardBox: BoxShape3D = $Board/BoardCollider.shape
	%Board.position = Vector3(0, boardBox.size.y/2.0, 0)
	# Magic constant
	%MainCamera3D.position = %Board.position + Vector3(0, 6.5, 0.5)
	%LevelLabel.text = self.name
	
	var level_number: int = int(self.name.substr(len("Level ")))
	var scene_name = lvlFileName + str(level_number) + "_2D.tscn"
	var scene = load(scene_name).instantiate()
	$"2DSubViewport".add_child(scene)
