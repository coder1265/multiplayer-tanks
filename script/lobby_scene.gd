extends Control

@onready var player_list_display: ItemList = %player_list_display
@onready var tabs = %TabContainer
@onready var start_button = %game_start
@onready var chat_log: ItemList = %chat_log
@onready var chat_input: LineEdit = %chat_inputbox

func _ready():
	NetworkManager.player_list_changed.connect(_update_list)
	_update_list() # players may have already joined before this scene loaded
	var is_host := multiplayer.is_server()
	tabs.set_tab_hidden(tabs.get_tab_idx_from_control($Margin/lobby_holder/HBoxContainer/lobby_tap_pannel/TabContainer/host_tab2), not is_host)
	start_button.visible = is_host
	
	chat_input.max_length = 40
	chat_input.text_submitted.connect(_on_chat_submitted)
	NetworkManager.chat_message_recieved.connect(_on_chat_message)

func _update_list():
	player_list_display.clear()
	for id in NetworkManager.players:
		player_list_display.add_item("%s (id %d)" % [NetworkManager.players[id], id]) # once finished debugging eliminate id

func _on_chat_submitted(text:String) -> void:
	if text.strip_edges() == "":
		return
	NetworkManager.send_own_chat(text)
	chat_input.clear()

func _on_chat_message(id: int, text: String) -> void:
	var sender_name = NetworkManager.players.get(id, "???")
	chat_log.add_item("%s: %s" % [sender_name, text])
	chat_log.ensure_current_is_visible()

func _on_game_start_pressed() -> void:
	print("game started, players are ",NetworkManager.players)
	get_tree().change_scene_to_file("res://scenes/maps.tscn")
