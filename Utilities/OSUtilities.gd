extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

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
			var result = OS.execute("PowerShell.exe", ["-Command", PSNOTIF % [cleanText, "Information", cleanTitle]], true, output) #  -windowstyle hidden {. .\notification.ps1 }")
			print("Result: %d", result)
			print(output)
		_:
			print("NO NOTIFICATION HANDLER FOR " + osname)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
