extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func pass_input(input):
	$Sprite2D.receive(input)

func poll_position():
	return $Sprite2D.position.x
