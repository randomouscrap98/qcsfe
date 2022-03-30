extends Node

const BYTIMEINTERVAL = 3
const MINICONTENTFIELDS = "id,name,permissions,createDate,createUserId,contentType,parentId,literalType,meta,hash,deleted"

var userAutoFields = {
	"createUserId" : "createUser",
	"editUserId" : "editUser"
}
var contentAutoFields = {
	"contentId" : "content",
	"parentId" : "parent"
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func GetStandardHeaders():
	return [ "Content-Type: application/json", "accepts: application/json"]

func TimeMessageKey(i):
	return "msg%d" % i
func TimeActivityKey(i):
	return "act%d" %i

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
	var contentRequest = {
		"type" : "content",
		"fields" : MINICONTENTFIELDS,
		"query" : ""
	}
	# DateStart is the very beginning of the given day
	var dateStart = OSUtilities.GetDayStart(date)
	var utcOffset = OSUtilities.GetUtcOffset()
	var baseUtc = OS.get_unix_time_from_datetime(dateStart) - utcOffset * 60 * 60
	# Need to include the LAST part because they're RANGES
	for i in range(0, 25, BYTIMEINTERVAL):
		var nowKey = "date%d" % i
		var lastKey = "date%d" % (i - BYTIMEINTERVAL)
		var msgKey = TimeMessageKey(i)
		var actKey = TimeActivityKey(i)
		# Dates are reversed, so go to 24 hours from now, then start subtracting hours
		var nowDate = OS.get_datetime_from_unix_time(baseUtc + OSUtilities.DAYSECS - 60*60*i)
		values[nowKey] = "%d-%02d-%02d %02d" % [ nowDate["year"], nowDate["month"], nowDate["day"], nowDate["hour"] ]
		if i > 0:
			requests.append({
				"name" : msgKey,
				"type" : "message_aggregate",
				"fields" : "*",  # REMEMBER, time goes backwards here! So "nowKey" is the LOWER bound!!
				"query" : "!null(module) and createDate >= @%s and createDate < @%s" % [ nowKey, lastKey ]
			})
			requests.append({
				"name" : actKey,
				"type" : "activity_aggregate",
				"fields" : "*",
				"query" : "createDate >= @%s and createDate < @%s" % [ nowKey, lastKey ]
			})
			if i > BYTIMEINTERVAL:
				userRequest.query += " or "
				contentRequest.query += " or "
			userRequest.query += "id in @%s.createUserId or id in @%s.createUserId" % [ msgKey, actKey ]
			contentRequest.query += "id in @%s.contentId or id in @%s.contentId" % [ msgKey, actKey ]
	requests.append(userRequest)
	requests.append(contentRequest)
	return {
		"type" : "request",
		"data" : {
			"values" : values,
			"requests" : requests
		}
	}

# Return a dictionary with all the ids as keys
func IdDictionary(content):
	var result = {}
	for c in content:
		result[str(c["id"])] = c
	return result

func AutoLinkGeneric(content, link, linkFields, type):
	for c in content:
		for f in linkFields:
			if f in c:
				var key = str(c[f])
				if key in link:
					c[linkFields[f]] = link[key]
				else:
					printerr("Couldn't find %s %s in result!" % [ type, key ])
					c[linkFields[f]] = { "id" : key }

# Link users to standard user fields in given content, assume users is already id linked
func AutoLinkUsers(content, users):
	AutoLinkGeneric(content, users, userAutoFields, "user")

func AutoLinkContent(content, contentLink):
	AutoLinkGeneric(content, contentLink, contentAutoFields, "content")

# Given the pure data from a response generated by CreateByTimeRequest, link everything together
func AutoLinkByTimeRequest(data):
	var users = IdDictionary(data.user)
	var content = IdDictionary(data.content)
	var result = { }
	for i in range(BYTIMEINTERVAL, 25, BYTIMEINTERVAL):
		var msgKey = TimeMessageKey(i)
		var actKey = TimeActivityKey(i)
		# Skip empty times
		#if data[msgKey].size() == 0 && data[actKey].size() == 0: # && result.size() == 0:
		#	continue
		AutoLinkUsers(data[msgKey], users)
		AutoLinkContent(data[msgKey], content)
		AutoLinkUsers(data[actKey], users)
		AutoLinkContent(data[actKey], content)
		var timeKey = "%d:00" % (24 - i)
		if BYTIMEINTERVAL > 1:
			timeKey = "%s - %d:00" % [ timeKey, (24 - i + BYTIMEINTERVAL - 1) ]
		result[timeKey] = {
			"messages" : data[msgKey],
			"activity" : data[actKey]
		}
	return result

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
