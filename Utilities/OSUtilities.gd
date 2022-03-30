extends Node

const DAYSECS = 60 * 60 * 24
const PSNOTIF = "[void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); $objNotifyIcon=New-Object System.Windows.Forms.NotifyIcon; $objNotifyIcon.BalloonTipText='%s'; $objNotifyIcon.Icon=[system.drawing.systemicons]::%s; $objNotifyIcon.BalloonTipTitle='%s'; $objNotifyIcon.BalloonTipIcon='None'; $objNotifyIcon.Visible=$True; $objNotifyIcon.ShowBalloonTip(5000);"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func CleanInput(text: String):
	return text.replace("'", "''").replace("\\", "\\\\")
	
func SendNotification(title: String, text: String):
	var osname = OS.get_name()
	match osname:
		"Windows":
			var cleanTitle  = CleanInput(title)
			var cleanText = CleanInput(text)
			var output = []
			var result = OS.execute("powershell.exe", ["-windowstyle", "hidden", "-Command", PSNOTIF % [cleanText, "Information", cleanTitle]], true, output) #  -windowstyle hidden {. .\notification.ps1 }")
			print("Result: %d" % result)
			print(output)
		_:
			print("NO NOTIFICATION HANDLER FOR " + osname)

# Return the amount of hour offset from UTC we are. For instance, EST should return
# -4 or -5 based on the DST setting
func GetUtcOffset():
	var utc = OS.get_datetime(true)
	var ours = OS.get_datetime()
	var dayOffset = ours["day"] - utc["day"]
	# If days are same, 0. If days are 1 apart, 1 or -1. If ours = 31 and theirs = 1, sign = 1, offset = -1.
	# if ours = 1 and theirs = 31, sign = -11, offset = 1
	if abs(dayOffset) > 1:
		dayOffset = -sign(dayOffset)
	return 24 * dayOffset + (ours["hour"] - utc["hour"])

func GetDayStart(date):
	var dateStart = date.duplicate()
	dateStart["hour"] = 0
	dateStart["minute"] = 0
	dateStart["second"] = 0
	return dateStart
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
