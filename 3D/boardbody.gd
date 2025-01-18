extends RigidBody3D

func _ready() -> void:
	set_inertia(Vector3(2, 2, 2))
	set_angular_damp(1)
	%"2DLevelManager".set_stand_x(%Stand.position.x)

func _physics_process(delta: float) -> void:
	tilt_board_based_on_masses(delta)

func _input(event: InputEvent):
	if event is not InputEventKey:
		return
	
	if (is_inside_tree() and $"../SubViewport".is_inside_tree()):
		$"../SubViewport".push_input(event)

func tilt_board_based_on_masses(delta: float) -> void:
	var torque_at_one = %"2DLevelManager".get_torque()
	var multiplier = 0.05
	var force_to_apply = torque_at_one * Vector3.DOWN * delta * multiplier
	var force_location = Vector3(1, 0, 0)
	apply_force(force_to_apply, force_location)
