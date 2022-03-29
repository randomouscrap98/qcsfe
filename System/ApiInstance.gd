extends Node

const RECONNECTINTERVAL = 5.0

var apiUrl : String = ""
var wsUrl : String = ""
var userToken : String = ""

var queuedRequests = []
var currentRequest = null
var request
var client

var doReconnect : bool = false
var reconnectTimer = 0

signal login_success()
signal login_error(message)
signal all_error(message)

signal ws_connected()
signal ws_disconnected()
signal ws_badtoken(message)
signal ws_unhandled(message)

# Called when the node enters the scene tree for the first time.
func _ready():
	request = HTTPRequest.new()
	client = WebSocketClient.new()
	add_child(request)
	request.connect("request_completed", self, "_request_completed")
	
	# According to examples, connect signals only once, because you can reuse the
	# client object forever, even after closing and reopening.
	client.connect("connection_closed", self, "_ws_closed")
	# client.connect("connection_error", self, "_ws_error")
	client.connect("connection_established", self, "_ws_open")
	client.connect("data_received", self, "_ws_message")


# Standard non-state functions
func GetStandardHeaders():
	return [ "Content-Type: application/json", "accepts: application/json"]


func _ws_closed(_clean = false):
	printerr("Websocket to %s closed, clean: %d" % [ wsUrl, _clean ])
	emit_signal("ws_disconnected")
	# This will reconnect very fast, as fast as possible!
	if doReconnect:
		ConnectWs()

func _ws_open(_proto = ""):
	print("Websocket opened to %s, sending token" % wsUrl)

func _ws_message():
	pass

func DisconnectWs():
	if doReconnect:
		print("Forcing disconnect to ws %s" % wsUrl)
		doReconnect = false
		client.disconnect_from_host(1000, "Client forced disconnect?")
	else:
		print("Disconnect called, but no websocket seemingly running")

func ConnectWs(timeout = 0):
	reconnectTimer = timeout
	
# Actual stateful functions (ugh)
func ReInitialize(url : String, loginData):
	DisconnectWs()
	apiUrl = url
	wsUrl = url.replace("http", "ws") + "/live/ws" # This could be dangerous (the replace) but whatever
	var loginUrl  = url + "/user/login"
	print("Login (ReInitialize) requesting URL: %s" % loginUrl)
	QueueRequestPost(loginUrl, GetStandardHeaders(), JSON.print(loginData), "Login")

func login_success_func(body, _data):
	print("Login success; user token: %s" % body)
	userToken = body
	emit_signal("login_success")

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
	if reconnectTimer > 0:
		reconnectTimer = reconnectTimer - _delta
		if reconnectTimer <= 0:
			var err = client.connect_to_url(wsUrl)
			if err != OK:
				var errmessage = "COULDN'T INITIALIZE WEBSOCKET TO %s: call returned %d" % [ wsUrl, err ]
				printerr(errmessage)
				emit_signal("ws_unhandled", errmessage)
			else:
				doReconnect = true
			

func _request_completed(_result, response_code, _headers, body):
	var completedRequest = currentRequest
	currentRequest = null
	var bodstring = body.get_string_from_utf8()
	if response_code == 200:
		print("%s: %d (%d bytes)" % [completedRequest.url, response_code, body.size()])
		self.call(completedRequest.success_func, bodstring, completedRequest.data)
	else:
		EmitError(completedRequest.what, "ERROR: %d: %s" % [response_code, bodstring], completedRequest.error_signals)
