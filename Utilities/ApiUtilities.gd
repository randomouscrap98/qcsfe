extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func GetStandardHeaders():
	return [ "Content-Type: application/json", "accepts: application/json"]

# Assume date is local time, again. But we only look at the date portion anyway, not the time.
func CreateByTimeRequest(date):
	var result = {}
	var values = {}
	var requests = []
	var userRequest = {
		"type" : "user",
		"fields" : "*",
		"query" : ""
	}
	# DateStart is the very beginning of the given day
	var dateStart = OSUtilities.GetDayStart(date)
	var utcOffset = OSUtilities.GetUtcOffset()
	var baseUtc = OS.get_unix_time_from_datetime(dateStart) - utcOffset
	# Need to include the LAST part because they're RANGES
	for i in range(0, 25):
		var nowKey = "date%d" % i
		var lastKey = "date%d" % (i - 1)
		var msgKey = "msg%d" % i
		var actKey = "act%d" % i
		# Dates are reversed, so go to 24 hours from now, then start subtracting hours
		var nowDate = OS.get_datetime_from_unix_time(baseUtc + OSUtilities.DAYSECS - 60*60*i)
		values[nowKey] = "%d-%02d-%02dT%02d:00:00" % [ nowDate["year"], nowDate["month"], nowDate["day"], nowDate["hour"] ]
		if i > 0:
			requests.append({
				"name" : msgKey,
				"type" : "message_aggregate",
				"fields" : "*",
				"query" : "createDate >= @%s and createDate < @%s" % [ lastKey, nowKey ]
			})
			requests.append({
				"name" : actKey,
				"type" : "activity_aggregate",
				"fields" : "*",
				"query" : "createDate >= @%s and createDate < @%s" % [ lastKey, nowKey ]
			})
			if i > 1:
				userRequest.query += " or "
			userRequest.query += "id in @%s.createUserId or id in @%s.createUserId" % [ msgKey, actKey ]
	requests.append(userRequest)
	return {
		"type" : "request",
		"data" : {
			"values" : values,
			"requests" : requests
		}
	}
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
