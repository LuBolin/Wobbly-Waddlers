class_name HUD
extends CanvasLayer

@onready var turnDelayOverlay = $TurnOverlay

func _ready():
	self.visible = true # this was set to false in editor for easier tilemap editing
	Singleton.win.connect(self.win)
	Singleton.lose.connect(self.lose)
	turnDelayOverlay.set_visible(false)

func _input(event):
	if not(event is InputEventKey and event.pressed):
		return
	if turnDelayOverlay.visible: # won or lost
		return
	if event.get_keycode() == KEY_ESCAPE:
		self._on_to_main_menu_pressed()

func setDelayOverlay(visible):
	turnDelayOverlay.visible = visible

func win():
	turnDelayOverlay.color = Color(Color.GREEN_YELLOW, 0.3)
	turnDelayOverlay.visible = true
	
	get_tree().create_timer(1.5).timeout.connect(self._on_to_main_menu_pressed)

func lose():
	turnDelayOverlay.color = Color(Color.RED, 0.5)
	turnDelayOverlay.visible = true
	
	get_tree().create_timer(0.8).timeout.connect(func x(): Singleton.restart.emit())
	

const mainSceneFile = "res://Scenes/MainScreen.tscn"
func _on_to_main_menu_pressed():
	Singleton.to_menu.emit()
	get_tree().change_scene_to_file(mainSceneFile)
