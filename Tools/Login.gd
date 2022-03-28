extends PanelContainer

# onready var request = $HTTPRequest
onready var apiSelect = $MarginContainer/VBoxContainer/ApiEndpointSelect
onready var errorBox =$MarginContainer/VBoxContainer/MarginContainer6/ErrorBox
onready var loginButton = $MarginContainer/VBoxContainer/LoginButton
onready var passwordEdit = $MarginContainer/VBoxContainer/PasswordEdit
onready var usernameEdit = $MarginContainer/VBoxContainer/UsernameEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	ApiInstance.connect("login_error", self, "_login_error")
	ApiInstance.connect("login_success", self, "_login_success")
	# request.connect("request_completed", self, "_request_complete")
	loginButton.connect("pressed", self, "_login_pressed")
	passwordEdit.connect("text_entered", self, "_password_entered")

func SetError(text: String):
	print("Login seterror: %s" % text)
	errorBox.SetError(text)
	errorBox.show()

func ClearError():
	errorBox.SetError("")
	errorBox.hide()

func GetSelectedUrl():
	return apiSelect.get_item_text(apiSelect.get_selected_id())

func DisableControls():
	loginButton.disabled = true
	apiSelect.disabled = true

func EnableControls():
	loginButton.disabled = false
	apiSelect.disabled = false
	
func _password_entered(_text: String):
	_login_pressed()

func _login_error(message):
	EnableControls()
	SetError(message)

func _login_success():
	EnableControls()
	
func _login_pressed():
	DisableControls()
	ClearError()
	var apiUrl = GetSelectedUrl() + "/user/login"
	print("Login requesting URL: %s" % apiUrl)
	ApiInstance.ReInitialize(GetSelectedUrl(), { "username": usernameEdit.text, "password": passwordEdit.text })
	
# func _request_complete(_result, response_code, _headers, body):
# 	EnableControls()
# 	var bodstring = body.get_string_from_utf8()
# 	if response_code != 200:
# 		SetError("ERROR %d: %s" % [response_code, bodstring])
# 	else:
# 		emit_signal("login_success", GetSelectedUrl(), bodstring)

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
