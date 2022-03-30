extends Node

# This is a wrapper class which wraps the websocket client. It provides provisions for reconnects,
# and emits specific signals for different kinds of messages and failures.

class_name WsWrapper

const RECONNECTINTERVAL = 5.0
const SENDINTERVAL = 0.1
const ERRORINTERVAL = 1

var wsUrl : String = ""
var token : String = ""
var lastId = 0
var sendTimeout = 0

var client

var isOpen : bool = false
var looping : bool = false
var reconnectTimer = 0
var sendCounter : int = 0

var pendingSends = []

# Just informational signals, use for state tracking for like a connection identifier.
# Also can check "isOpen", should match the state from the signals...
signal ws_connected()
signal ws_disconnected()

# All technically error signals, these errors indicate that the system has fully shutdown
# and will not open back up until someone calls connect (no more reconnect looping). Note
# that the individual signals such as "badtoken" and "unexpected" are there just in case;
# an error such as this ALWAYS emits the "ws_fulldisconnect" though.
signal ws_fulldisconnect(message)
signal ws_badtoken(message)
signal ws_unexpected(message)

signal ws_request(response)
signal ws_live(response)
signal ws_userlist(response, full)


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
func _process(delta):
	client.poll()
	if looping && reconnectTimer > 0:
		reconnectTimer = reconnectTimer - delta
		if reconnectTimer <= 0:
			_internal_connect()
	sendTimeout = max(0, sendTimeout - delta)
	if isOpen && sendTimeout <= 0 && pendingSends.size() > 0:
		client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
		var err = client.get_peer(1).put_packet(pendingSends[0])
		if err != OK:
			printerr("Couldn't send websocket request to %s: error code %d" % [ wsUrl, err ])
			sendTimeout += ERRORINTERVAL
		else:
			print("Sending %d bytes on websocket %s" % [ pendingSends[0].size(), wsUrl])
			pendingSends.pop_front()
			sendTimeout += SENDINTERVAL


func _ws_closed(_clean = false):
	printerr("Websocket to %s closed, clean: %s" % [ wsUrl, _clean ])
	isOpen = false
	emit_signal("ws_disconnected")
	if looping:
		reconnectTimer = RECONNECTINTERVAL

func _ws_open(_proto = ""):
	print("Websocket opened to %s! System is fully functional, but waiting for lastid message" % wsUrl)

func _ws_message():
	var message = client.get_peer(1).get_packet().get_string_from_utf8()
	var response = JSON.parse(message).result
	
	if response.type == "live":
		lastId = response.data.lastId
		emit_signal("ws_live", response)
	elif response.type == "lastId":
		# Weird note: we DON'T assume the socket is open until it sends us this message, because
		# the socket could close if the token was bad before anything happens, and that's not fun
		print("Websocket at %s is fully operational, lastId: %d" % [wsUrl, response.data])
		isOpen = true
		lastId = response.data
		emit_signal("ws_connected")
	elif response.type == "userlistupdate":
		emit_signal("ws_userlist", response, false)
	elif response.type == "userlist":
		emit_signal("ws_userlist", response, true)
	elif response.type == "request":
		emit_signal("ws_request", response)
	elif response.type == "badtoken":
		emit_signal("ws_badtoken", response.error)
		Disconnect(true, response.error)
	elif response.type == "unexpected":
		emit_signal("ws_unexpected", response.error)
		Disconnect(true, response.error)
	else:
		printerr("Unknown ws response type: %s" % response.type)


func Disconnect(force: bool = false, message: String = ""):
	if looping || force: # This variable basically says the system is running
		print("Forcing disconnect to ws %s" % wsUrl)
		if message != "":
			printerr("DISCONNECT MESSAGE: %s" % message)
		looping = false
		reconnectTimer = 0
		token = ""
		wsUrl = ""
		isOpen = false
		client.disconnect_from_host(1000, "Client forced disconnect?")
		emit_signal("ws_fulldisconnect", message)
	else:
		print("Disconnect called, but no websocket seemingly running")

func Connect(url, userToken): # , timeout = 0.00001):
	token = userToken
	wsUrl = url
	reconnectTimer = 0
	looping = true
	lastId = 0
	_internal_connect()

func Send(data, id : String = ""):
	sendCounter += 1
	if id == "":
		id = "GODOT_SEND_%d" % sendCounter
	data.id = id
	var sData = JSON.print(data)
	pendingSends.append(sData.to_utf8())
	return id

func _internal_connect():
	print("Connecting to websocket %s" % wsUrl)
	var err = client.connect_to_url("%s?token=%s&lastId=%d" % [ wsUrl, token, lastId ] )
	if err != OK:
		var errmessage = "COULDN'T INITIALIZE WEBSOCKET TO %s: call returned %d" % [ wsUrl, err ]
		printerr(errmessage)
		emit_signal("ws_unhandled", errmessage)
		Disconnect(true)
