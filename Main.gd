extends Control

onready var homepage = preload("res://Tools/Homepage.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	ApiInstance.connect("login_success", self, "_login_success")
	pass # Replace with function body.

func _login_success():#url: String, token: String):
	# print("Login successful, using URL %s", url)
	$Login.queue_free()
	add_child(homepage.instance())
	OS.request_attention()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
