extends Node

const PORT = 8888;
var peer = ENetMultiplayerPeer.new();
var players := {};
signal player_list_changed
enum State { OFFLINE, HOSTING, CONNECTED }
var state: State
signal state_changed
signal connection_error(message: String)

func _ready():
	print("network manager called")
	state = State.OFFLINE

func host_game(player_name: String):
	if state != State.OFFLINE:
		return # already hosting or connected, ignore
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, 8)
	if err != OK:
		print("Failed to host: ", err)
		return
	multiplayer.multiplayer_peer = peer
	players[1] = player_name
	state = State.HOSTING
	state_changed.emit()
	print("state is ", state)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	return true

func join_game(ip: String, player_name: String):
	print("join game function is called")
	if state != State.OFFLINE:
		return
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, PORT)
	if err != OK:
		connection_error.emit("Failed to create client: error %d" % err)
		return
	multiplayer.multiplayer_peer = peer
	print(multiplayer.multiplayer_peer)
	multiplayer.connected_to_server.connect(func():
		state = State.CONNECTED
		state_changed.emit()
		print("this is state", state)
		_register_self(player_name)
	)
	multiplayer.connection_failed.connect(func(): connection_error.emit("Connection failed — server unreachable or not hosting"))

func _register_self(player_name: String):
	rpc_id(1, "register_player", player_name)

@rpc("any_peer", "reliable")
func register_player(player_name: String):
	var id = multiplayer.get_remote_sender_id()
	players[id] = player_name
	_sync_players.rpc(players)

@rpc("authority", "reliable", "call_local")
func _sync_players(new_players: Dictionary):
	players = new_players
	player_list_changed.emit()

func _on_peer_connected(id: int):
	print("Peer connected: ", id)

func _on_peer_disconnected(id: int):
	players.erase(id)
	_sync_players.rpc(players)
	print("Peer disconnected: ", id)
