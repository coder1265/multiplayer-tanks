extends Control

@onready var player_list_display: ItemList = %player_list_display

func _ready():
	NetworkManager.player_list_changed.connect(_update_list)
	_update_list() # players may have already joined before this scene loaded

func _update_list():
	player_list_display.clear()
	for id in NetworkManager.players:
		player_list_display.add_item("%s (id %d)" % [NetworkManager.players[id], id]) # once finished debugging eliminate id
