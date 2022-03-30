extends VBoxContainer

onready var hourLabel = $MarginContainer/HourLabel
onready var hourlyContent = preload("res://Fragments/HourlyContent.tscn")
onready var contentList = $ContentList

var tempHour = null
var tempData = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func reset():
	if tempHour != null:
		tempHour = null

# Data should be an object with "activity" and "messages" and each will be a list
# of the aggregate data
func SetData(hour, data):
	tempHour = hour
	tempData = data
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if tempHour != null:
		hourLabel.text = tempHour
		tempHour = null
	if tempData != null:
		NodeUtilities.ClearNode(contentList)
		var contents = {}
		TallyContent(contents, tempData.messages)
		TallyContent(contents, tempData.activity)
		for c in contents:
			var hc = hourlyContent.instance()
			hc.SetData(contents[c].content, contents[c].users)
			contentList.add_child(hc)
		tempData = null

func TallyContent(contents, aggregates):
	for a in aggregates:
		var key = str(a.contentId)
		if !(key in contents):
			contents[key] = {
				"content" : a.content,
				"users" : []
			}
