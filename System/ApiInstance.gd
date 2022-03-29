extends Node


var apiUrl : String = ""
var userToken : String = ""

var queuedRequests = []
var currentRequest = null
var request
var websocket

signal login_success()
signal login_error(message)
signal all_error(message)


# Called when the node enters the scene tree for the first time.
func _ready():
	request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_request_completed")
	websocket = WsWrapper.new()
	add_child(websocket)

# Standard non-state functions
func GetStandardHeaders():
	return [ "Content-Type: application/json", "accepts: application/json"]


	
# Actual stateful functions (ugh)
func ReInitialize(url : String, loginData):
	websocket.Disconnect()
	apiUrl = url
	# wsUrl = url.replace("http", "ws") + "/live/ws" # This could be dangerous (the replace) but whatever
	var loginUrl  = url + "/user/login"
	print("Login (ReInitialize) requesting URL: %s" % loginUrl)
	QueueRequestPost(loginUrl, GetStandardHeaders(), JSON.print(loginData), "Login")

func login_success_func(body, _data):
	print("Login success; user token: %s" % body)
	userToken = body
	emit_signal("login_success")
	websocket.Connect(apiUrl.replace("http", "ws") + "/live/ws", userToken) # This could be dangerous (the replace) but whatever)

# Queueing functions
func QueueRequestPost(url: String, headers, data, what: String):
	QueueRequestRaw(url, headers, HTTPClient.METHOD_POST, data, what, what.to_lower() + "_success_func", [what.to_lower() + "_error"])

func QueueRequestRaw(url: String, headers, method, data, what, success_func, error_signals):
	queuedRequests.append({
		"url": url, 
		"headers": headers,
		"method": method,
		"data" : data,
		"what" : what,
		"success_func" : success_func,
		"error_signals" : error_signals
	})

func EmitError(what : String, message : String, signals):
	var newMessage = "[%s]: %s" % [ what, message ]
	emit_signal("all_error", newMessage)
	printerr(newMessage)
	for s in signals:
		emit_signal(s, newMessage)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if queuedRequests.size() > 0 && currentRequest == null:
		currentRequest = queuedRequests.pop_front()
		# This DOES NOT block for the entirety of the request!
		var error = request.request(currentRequest.url, currentRequest.headers, true, currentRequest.method, currentRequest.data)
		if error != OK:
			EmitError(currentRequest.what, "Unknown error from request: %s" % error, currentRequest.error_signals)
			currentRequest = null
			

func _request_completed(_result, response_code, _headers, body):
	var completedRequest = currentRequest
	currentRequest = null
	var bodstring = body.get_string_from_utf8()
	if response_code == 200:
		print("%s: %d (%d bytes)" % [completedRequest.url, response_code, body.size()])
		self.call(completedRequest.success_func, bodstring, completedRequest.data)
	else:
		EmitError(completedRequest.what, "ERROR: %d: %s" % [response_code, bodstring], completedRequest.error_signals)
