extends RigidBody3D

const FORCE_VECTOR: Vector3 = Vector3(0, 5, 0)
const FORCE_MULTIPLIER: float = 0.01

func _ready() -> void:
	set_inertia(Vector3(2, 2, 2))
	set_angular_damp(1)

func _process(delta: float) -> void:
	tilt_board_based_on_masses(delta)

func _input(key: InputEvent):
	if key is InputEventKey:
		if key.keycode == KEY_LEFT or key.keycode == KEY_RIGHT:
			$"../SubViewport/Sample2d".pass_input(key)

func tilt_board_based_on_masses(delta: float) -> void:
	var tilt_amount = $"../SubViewport/Sample2d".poll_position()
	#if tilt_amount > 0:
		#apply_force(FORCE_VECTOR, Vector3(-delta * FORCE_MULTIPLIER * tilt_amount, 0, 0))
	#elif tilt_amount < 0:
		#apply_force(FORCE_VECTOR, Vector3(delta * FORCE_MULTIPLIER, 0, 0))
	apply_force(FORCE_VECTOR, Vector3(-delta * FORCE_MULTIPLIER * tilt_amount, 0, 0))
