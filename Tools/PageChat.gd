extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var toggleExtra = $Header/TitlePanel/HBoxContainer/ToggleExtra #$VBoxContainer/TitlePanel/HBoxContainer/ToggleExtra
onready var extraPanel = $Header/ExtraPanel

# Called when the node enters the scene tree for the first time.
func _ready():
	toggleExtra.connect("toggled", self, "_toggle_extra")
	pass # Replace with function body.

func _toggle_extra(_state):
	if toggleExtra.is_pressed():
		extraPanel.show()
	else:
		extraPanel.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
