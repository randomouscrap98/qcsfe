extends VBoxContainer

var currentDate : Dictionary
onready var activityList : Node = $ScrollContainer/ActivityList
onready var dateLabel : Node = $Header/HBoxContainer/DateRangeLabel
onready var oldButton : Node = $Header/HBoxContainer/OlderButton
onready var newButton : Node = $Header/HBoxContainer/NewerButton

var lastSendId : String = ""

onready var loading  = preload("res://Fragments/ContainerLoading.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	oldButton.connect("pressed", self, "_date_back")
	newButton.connect("pressed", self, "_date_forward")
	ApiInstance.websocket.connect("ws_request", self, "_request_get")
	LoadDate()
	pass # Replace with function body.


# This function only looks at the year, month, and day part of the date object. It is assumed
# the date is based on local time, and will be converted to UTC for the server
func LoadDate(date = OS.get_datetime()):
	NodeUtilities.ClearNode(activityList)
	activityList.add_child(loading.instance())
	dateLabel.text = "%d/%02d/%02d" % [date["year"], date["month"], date["day"]]
	currentDate = date.duplicate()
	currentDate["hour"] = 12 # For safety, put it in the MIDDLE of the day
	var today = OS.get_datetime()
	newButton.disabled = today["year"] == date["year"] && today["month"] == date["month"] && today["day"] == date["day"]
	lastSendId = ApiInstance.websocket.Send(ApiUtilities.CreateByTimeRequest(date))


func LoadDateFromOffset(days):
	var unixTime = OS.get_unix_time_from_datetime(currentDate)
	var modifiedTime = unixTime + (days * OSUtilities.DAYSECS)
	LoadDate(OS.get_datetime_from_unix_time(modifiedTime))
	
func _date_back():
	LoadDateFromOffset(-1)

func _date_forward():
	LoadDateFromOffset(1)

func _request_get(response):
	if response.id == lastSendId:
		print("Got response, matched id %s" % lastSendId)
	else:
		printerr("Got response that wasn't ours: %s vs %s (ours first)" % [ lastSendId, response.id ])

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
