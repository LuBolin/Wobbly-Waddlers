extends RigidBody3D
@onready var _2d_sub_viewport: SubViewport = $"../2DSubViewport"

const TORQUE_MULTIPLIER: float = 0.03

func _ready() -> void:
	# arbitrary constant
	set_inertia(Vector3(2, 2, 2))
	# set_angular_damp(3) # works with torque multiplier 0.03
	set_angular_damp(3.5)
	await get_tree().process_frame
	_2d_sub_viewport.get_child(0).set_stand_x(%Stand.position.x)
	self.body_exited.connect(on_body_exited)
	Singleton.win.connect(
		func(): self.set_physics_process(false)
	)

func _physics_process(delta: float) -> void:
	if not _2d_sub_viewport.get_child_count() > 0:
		return
	tilt_board_based_on_masses(delta)

func on_body_exited(body: Node3D):
	if body == %Stand and abs(self.rotation.z) > PI/4.0:
		Singleton.lose.emit()

func _input(event: InputEvent):
	if event is not InputEventKey:
		return
	
	if (self and is_inside_tree() and _2d_sub_viewport.is_inside_tree()):
		_2d_sub_viewport.push_input(event)

func tilt_board_based_on_masses(delta: float) -> void:
	var torque_at_one = _2d_sub_viewport.get_child(0).get_torque()
	var force_to_apply = torque_at_one * Vector3.DOWN * delta * TORQUE_MULTIPLIER
	var force_location = Vector3(1, 0, 0)
	apply_force(force_to_apply, force_location)
