extends VBoxContainer


onready var paneToggle = $Header/HBoxContainer/PaneToggle
onready var rightPane = $MainSplit/RightPane
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	paneToggle.connect("toggled", self, "_pane_toggled")

func _pane_toggled(_state):
	if paneToggle.is_pressed():
		rightPane.show()
	else:
		rightPane.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
