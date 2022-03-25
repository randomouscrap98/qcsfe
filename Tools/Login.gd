extends Panel

signal login_success(url, token)

onready var request = $HTTPRequest
onready var apiSelect = $VBoxContainer/ApiEndpointSelect
onready var errorBox =$VBoxContainer/MarginContainer6/ErrorBox
onready var loginButton = $VBoxContainer/LoginButton

# Called when the node enters the scene tree for the first time.
func _ready():
	request.connect("request_completed", self, "_request_complete")
	loginButton.connect("pressed", self, "_login_pressed")
	pass # Replace with function body.

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
	
func _login_pressed():
	DisableControls()
	ClearError()
	var apiUrl = GetSelectedUrl()
	print("URL: %s" % apiUrl)
	var data = { "username": $VBoxContainer/UsernameEdit.text, "password": $VBoxContainer/PasswordEdit.text }
	var error = request.request(apiUrl + "/user/login", ApiUtilities.GetStandardHeaders(), true,HTTPClient.METHOD_POST, JSON.print(data))
	if error != OK:
		SetError("Unknown error from request: %s" % error)
		EnableControls()
	
func _request_complete(_result, response_code, _headers, body):
	EnableControls()
	var bodstring = body.get_string_from_utf8()
	if response_code != 200:
		SetError("ERROR %d: %s" % [response_code, bodstring])
	else:
		emit_signal("login_success", GetSelectedUrl(), bodstring)

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
