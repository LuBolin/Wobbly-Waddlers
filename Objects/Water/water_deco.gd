extends AnimatedSprite2D

@onready var water_deco: AnimatedSprite2D = $"."

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	var random_initial_frame = rng.randi_range(0, 3)
	water_deco.set_frame(random_initial_frame)
