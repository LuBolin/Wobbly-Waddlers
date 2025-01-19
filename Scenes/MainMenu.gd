extends Node2D

@onready var buttonsGrid = $ControlsGroup/LevelButtons

const lvlFileName = "res://Levels/Level"

func _ready():
	for button in buttonsGrid.get_children():
		button.pressed.connect(func x(): gotoLevel(button.name))
	$"ControlsGroup/99".pressed.connect(func x(): gotoLevel($"ControlsGroup/99".name))
	self.renderBeaten()

const numberKeys = [
	KEY_0, KEY_1, KEY_2, KEY_3, KEY_4,
	KEY_5, KEY_6, KEY_7, KEY_8, KEY_9
]

func _unhandled_input(event):
	if not(event is InputEventKey and event.pressed):
		return
	var index = numberKeys.find(event.get_keycode(), 0)
	if index > 0:
		gotoLevel(index)

func gotoLevel(button_name):
	var fileName = lvlFileName + str(button_name) + '.tscn'
	get_tree().change_scene_to_file(fileName)

func renderBeaten():
	Singleton.load_data()
	var levelButtons = buttonsGrid.get_children()
	for index in levelButtons.size():
		var button = levelButtons[index]
		# red_tick
		var beaten = Singleton.levelsBeaten \
			and (index+1) in Singleton.levelsBeaten
		if beaten:
			if button.get_child_count() > 0:
				button.get_child(0).visible = true
		else:
			if button.get_child_count() > 0:
				button.get_child(0).visible = false

func _on_clear_beaten_button_pressed():
	Singleton.levelsBeaten = []
	Singleton.save_data()
	renderBeaten()
