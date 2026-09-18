extends Control

@onready var name_input = $VBoxContainer2/VBoxContainer2/name_input
@onready var ip_input = $VBoxContainer2/VBoxContainer2/ip_input 
@onready var host_btn: TextureButton = $VBoxContainer2/VBoxContainer/host_button
@onready var join_btn: Button = $VBoxContainer2/VBoxContainer/join_button 


const IP_REGEX_PATTERN = "^(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})$"
var ip_regex := RegEx.new()

func _ready():
	ip_regex.compile(IP_REGEX_PATTERN)
	name_input.text_changed.connect(_validate)
	ip_input.text_changed.connect(_validate)
	_validate("") # run once at start so buttons start disabled

func _validate(_new_text := ""):
	var name_ok = name_input.text.strip_edges().length() > 0
	var ip_ok = _is_valid_ip(ip_input.text)
	print("name_ok: ", name_ok, " ip_ok: ", ip_ok, " ip text: '", ip_input.text, "'")

	host_btn.disabled = not name_ok
	join_btn.disabled = not (name_ok and ip_ok)

func _is_valid_ip(ip: String) -> bool:
	var result = ip_regex.search(ip)
	if not result:
		return false
	# also check each octet is 0-255, not just 1-3 digits
	for i in range(1, 5):
		var octet = int(result.get_string(i))
		if octet < 0 or octet > 255:
			return false
	return true

func _on_host_btn_pressed():
	if NetworkManager.state != 0:
		var signalemmited: bool = NetworkManager.host_game(name_input.text.strip_edges())
		#NetworkManager.state_changed.connect(_on_state_changed())
		if (signalemmited == true):
			_on_state_changed()
		print("hosted game")

func _on_join_btn_pressed():
	NetworkManager.join_game(ip_input.text, name_input.text.strip_edges())

func _on_state_changed():
	var offline = NetworkManager.state == NetworkManager.State.OFFLINE
	host_btn.disabled = not offline
	join_btn.disabled = not offline

	if NetworkManager.state == NetworkManager.State.HOSTING \
	or NetworkManager.state == NetworkManager.State.CONNECTED:
		get_tree().change_scene_to_file("res://scenes/lobby.tscn")
