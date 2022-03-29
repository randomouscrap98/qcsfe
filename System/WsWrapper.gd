extends Node

# This is a wrapper class which wraps the websocket client. It provides provisions for reconnects,
# and emits specific signals for different kinds of messages and failures.

class_name WsWrapper

const RECONNECTINTERVAL = 5.0

var wsUrl : String = ""
var token : String = ""
var lastId = 0

var client

var isOpen : bool = false
var looping : bool = false
var reconnectTimer = 0


signal ws_connected()
signal ws_disconnected()
signal ws_badtoken(message)
signal ws_unhandled(message)
signal ws_request(response)
signal ws_live(response)
signal ws_userlist(response)


# Called when the node enters the scene tree for the first time.
func _ready():
	client = WebSocketClient.new()
	
	# According to examples, connect signals only once, because you can reuse the
	# client object forever, even after closing and reopening.
	client.connect("connection_closed", self, "_ws_closed")
	client.connect("connection_established", self, "_ws_open")
	client.connect("data_received", self, "_ws_message")
	# client.connect("connection_error", self, "_ws_error")

func _exit_tree():
	Disconnect(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	client.poll()
	if looping && reconnectTimer > 0:
		reconnectTimer = reconnectTimer - _delta
		if reconnectTimer <= 0:
			_internal_connect()

func _ws_closed(_clean = false):
	printerr("Websocket to %s closed, clean: %d" % [ wsUrl, _clean ])
	isOpen = false
	emit_signal("ws_disconnected")
	if looping:
		reconnectTimer = RECONNECTINTERVAL

func _ws_open(_proto = ""):
	print("Websocket opened to %s! System is fully functional" % wsUrl)
	isOpen = true
	emit_signal("ws_connected")

func _ws_message():
	pass

func Disconnect(force: bool = false):
	if looping || force: # This variable basically says the system is running
		print("Forcing disconnect to ws %s" % wsUrl)
		looping = false
		reconnectTimer = 0
		token = ""
		wsUrl = ""
		isOpen = false
		client.disconnect_from_host(1000, "Client forced disconnect?")
	else:
		print("Disconnect called, but no websocket seemingly running")

func Connect(url, userToken): # , timeout = 0.00001):
	token = userToken
	wsUrl = url
	reconnectTimer = 0
	looping = true
	lastId = 0
	_internal_connect()

func _internal_connect():
	print("Connecting to websocket %s" % wsUrl)
	var err = client.connect_to_url("%s?token=%s&lastId=%d" % [ wsUrl, token, lastId ] )
	if err != OK:
		var errmessage = "COULDN'T INITIALIZE WEBSOCKET TO %s: call returned %d" % [ wsUrl, err ]
		printerr(errmessage)
		emit_signal("ws_unhandled", errmessage)
		Disconnect()
