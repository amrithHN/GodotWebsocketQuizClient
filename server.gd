extends Control

# The port we will listen to.
const PORT = 9080
# Our WebSocketServer instance.
var _server = WebSocketServer.new()

var num_clients=0
signal start_game
signal next_question
signal end_game

var players={}

func _ready():
	# Connect base signals to get notified of new client connections,
	# disconnections, and disconnect requests.
	_server.connect("client_connected", self, "_connected")
	_server.connect("client_disconnected", self, "_disconnected")
	_server.connect("client_close_request", self, "_close_request")
	# This signal is emitted when not using the Multiplayer API every time a
	# full packet is received.
	# Alternatively, you could check get_peer(PEER_ID).get_available_packets()
	# in a loop for each connected peer.
	_server.connect("data_received", self, "_on_data")
	# Start listening on the given port.
	var err = _server.listen(PORT)
	print("starting server...")
	if err != OK:
		print("Unable to start server")
		set_process(false)
	else:
		print("server started successfully on :",PORT)
	var file = File.new()
	file.open("res://Questions.json", file.READ)
	var json = file.get_as_text()
	var dict = JSON.parse(json).result
	print(dict[str(1)]["question"])
	print(dict[str(2)]["question"])
	


func _connected(id, proto):
	# This is called when a new peer connects, "id" will be the assigned peer id,
	# "proto" will be the selected WebSocket sub-protocol (which is optional)
	print("Client %d connected with protocol: %s" % [id, proto])
	num_clients+=1
	print("number of clients:",num_clients)
	var number=get_node("num")
	number.text=str(num_clients)
	#players[id]=num_clients
	#_server.get_peer(id).put_packet(str(num_clients).to_utf8())
	if(num_clients==2):
		#add a timer before starting game
		get_tree().change_scene("res://Questions.tscn")


func _close_request(id, code, reason):
	# This is called when a client notifies that it wishes to close the connection,
	# providing a reason string and close code.
	print("Client %d disconnecting with code: %d, reason: %s" % [id, code, reason])


func _disconnected(id, was_clean = false):
	# This is called when a client disconnects, "id" will be the one of the
	# disconnecting client, "was_clean" will tell you if the disconnection
	# was correctly notified by the remote peer before closing the socket.
	print("Client %d disconnected, clean: %s" % [id, str(was_clean)])
	num_clients-=1
	players.erase(id)
	var number=get_node("num")
	number.text=str(num_clients)


func _on_data(id):
	# Print the received packet, you MUST always use get_peer(id).get_packet to receive data,
	# and not get_packet directly when not using the MultiplayerAPI.
	var pkt = _server.get_peer(id).get_packet()
	print("Got data from client %d: %s ... echoing" % [id, pkt.get_string_from_utf8()])
	if players.get(id)==null:
		players[id]=pkt.get_string_from_utf8()
		print(id," ",players[id])
		var name= get_node("name")
		name.text=pkt.get_string_from_utf8()+" "+"joined"
		var timer=Timer.new()
		timer.set_one_shot(true)
		timer.set_wait_time(3)
		timer.connect("timeout",self,"_on_timeout_completed")
		add_child(timer)
		timer.start()
		
	if players.get(id):
		print(pkt.get_string_from_utf8())
		
		
		
func _on_timeout_completed():
	var name=get_node("name")
	name.text=""
	
func _process(_delta):
	# Call this in _process or _physics_process.
	# Data transfer, and signals emission will only happen when calling this function.
	_server.poll()


func _exit_tree():
	_server.stop()
