extends Control

@onready var name_input = $main_screen_buttons/name_input
@onready var play_btn: TextureButton = $main_screen_buttons/play_button

func _ready():
	name_input.text_changed.connect(_validate)
	NetworkManager.state_changed.connect(_on_state_changed)
	NetworkManager.connection_error.connect(_on_connection_error)
	_validate("")

func _validate(_new_text := ""):
	play_btn.disabled = name_input.text.strip_edges().length() == 0

func _on_host_btn_pressed(): # keep this name if it's already wired to the button's signal in the editor
	NetworkManager.play(name_input.text.strip_edges())

func _on_state_changed():
	if NetworkManager.state == NetworkManager.State.HOSTING \
	or NetworkManager.state == NetworkManager.State.CONNECTED:
		get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_connection_error(message: String):
	print("Connection error: ", message)
