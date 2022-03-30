extends HBoxContainer

var totalTime = 0
var frames = [ "-", "\\", "|", "/" ]
var frameCount = frames.size()
onready var loadingLabel = $MarginContainer/Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
# 	totalTime += delta
# 	var frame : int = totalTime * frameCount
# 	loadingLabel.text = loadingLabel.text.substr(0, loadingLabel.text.length() - 1) + frames[frame % frameCount]
