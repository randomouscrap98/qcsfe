extends VBoxContainer

onready var contentTitle = $ContentInfo/ContentTitle
onready var userlist = $UserList

var tempContent = null
var tempUserlist = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func SetData(content, users):
	tempContent = content
	tempUserlist = users
	

func _process(_delta):
	if tempContent:
		if "name" in tempContent:
			contentTitle.text = tempContent.name
		else:
			contentTitle.text = "??? (%s)" % tempContent.id
		tempContent = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
