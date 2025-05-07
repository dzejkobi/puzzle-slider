extends Node2D

@export var tile_amount: Vector2i = Vector2i(4, 4)
@export var game_mode: Consts.GameMode = Consts.GameMode.SWAP_VOID
@export var show_numbers: bool = true
@export var swap_time: float = 0.1
@export var shuffle_time: float = 0.05
@export var shuffle_count: int = 100
@export var play_music: bool = true
@export_file var bg_image_path: String = "res://media/img/koala.jpg"

@onready var solved_label: Label = $SolvedLabel
@onready var coll_shape: CollisionShape2D = $Area/CollShape
@onready var bg_image_rect: TextureRect = $BgImageRect

var tile_scene = preload("res://tile/tile.tscn")
var move_in_progress: bool = false
var void_tile: Tile = null
var curr_tile: Tile = null
var bg_image: Image
var is_solved: bool = false

const GAME_MODE_SETUP: = {
	Consts.GameMode.SWAP_VOID: {
		"shuffle_fn_name": "shuffle_tiles_void"
	},
	Consts.GameMode.SWAP_ANY: {
		"shuffle_fn_name": "shuffle_tiles_any"
	}
}


func set_bg_image(img_path: String, make_square: bool = true) -> void:
	var tile_size = get_tile_size()
	var img: = Image.new()
	img.load(img_path)
	bg_image = Graphics.make_rect_image(img)
	bg_image.resize(tile_size.x * tile_amount.x, tile_size.y * tile_amount.y)
	bg_image_rect.texture = ImageTexture.create_from_image(bg_image)


func get_tiles() -> Array[Tile]:
	var result: Array[Tile] = []
	result.assign(get_tree().get_nodes_in_group("tile"))
	return result


func get_solved_status() -> bool:
	var status := true
	for tile: Tile in get_tiles():
		if not tile.is_matching():
			status = false
	return status


func check_solved_status() -> void:
	is_solved = get_solved_status()
	if is_solved:
		var label_tween := get_tree().create_tween()
		var bg_tween :=  get_tree().create_tween()
		bg_image_rect.z_index = 90
		bg_image_rect.modulate.a = 1.0
		bg_tween.tween_property(bg_image_rect, "modulate:a", 1.0, 1.0)
		label_tween.tween_property(solved_label, "modulate:a", 1.0, 1.0)


func get_tile_size() -> Vector2i:
	return Vector2i(
		roundi(coll_shape.shape.size.x / tile_amount.x),
		roundi(coll_shape.shape.size.y / tile_amount.y)
	)


func set_tiles() -> void:
	for tile: Node in get_tiles():
		tile.queue_free()
	
	var tile_size: = get_tile_size()
	var tile: Tile
	var board_tl: = Vector2i(
		coll_shape.position - coll_shape.shape.size / 2
	)
	
	var ordinal: = 1
	var last_ordinal: = tile_amount.x * tile_amount.y
	var tile_bg_img: Image
	for y: int in range(tile_amount.y):
		for x: int in range(tile_amount.x):
			tile = tile_scene.instantiate()
			add_child(tile)

			@warning_ignore("integer_division")
			tile.setup({
				"size": tile_size,
				"position": Vector2i(
					board_tl.x + tile_size.x / 2 + x * tile_size.x,
					board_tl.y + tile_size.y / 2 + y * tile_size.y
				),
				"grid_position": Vector2i(x, y),
				"show_label": show_numbers,
				"ordinal": ordinal,
				# "bg_color": Color.DARK_CYAN,
				"bg_image": bg_image,
				"is_void": (
					ordinal == last_ordinal and
					game_mode == Consts.GameMode.SWAP_VOID
				)
			})
			if tile.is_void:
				void_tile = tile
			ordinal += 1


func shuffle_tiles_void(n_swaps: int, swp_time: float) -> void:
	var neighbours: Array[Tile]
	var tile_to_swap: Tile
	var last_tile: Tile = null
	var last_tile_index: int
	for i: int in range(n_swaps):
		neighbours = void_tile.get_neighbours()
		last_tile_index = neighbours.find(last_tile)
		if last_tile_index > -1:
			# do not reverse the last swap
			neighbours.remove_at(last_tile_index)
		tile_to_swap = neighbours[randi_range(0, len(neighbours) - 1)]
		void_tile.swap_position_with_tile(tile_to_swap, swp_time)
		last_tile = tile_to_swap

		# wait until both tiles signaled end of movement
		await EventBus.tile_move_stop
		await EventBus.tile_move_stop
		
		# Additional timeout as workarround to the bug when tiles
		# are not swapped correctly if the swap time is below 0.12 sec.
		await get_tree().create_timer(0.01).timeout
		
		
func shuffle_tiles_any(n_swaps: int, swp_time: float) -> void:
	var last_tiles: Array[Tile] = []
	var curr_tiles: Array[Tile]
	var avail_tiles: Array[Tile]
	var neighbours: Array[Tile]
	var index: int
	
	for i: int in range(n_swaps):
		curr_tiles = []
		avail_tiles = get_tiles()
		for last_tile: Tile in last_tiles:
			# removing last used tiles from the available choices
			# to avoid duplicating moves
			index = avail_tiles.find(last_tile)
			if index > -1:
				avail_tiles.remove_at(index)
		
		# choosing the first current tile randomly
		curr_tiles.append(avail_tiles[randi_range(0, len(avail_tiles) - 1)])
		
		# choosing the second one randomly from the neighbours
		neighbours = curr_tiles[0].get_neighbours()
		curr_tiles.append(neighbours[randi_range(0, len(neighbours) - 1)])
		curr_tiles[0].swap_position_with_tile(curr_tiles[1], swp_time)
		last_tiles.assign(curr_tiles)
		
		# wait until both tiles signaled end of movement
		await EventBus.tile_move_stop
		await EventBus.tile_move_stop
		

func _on_tile_clicked(tile: Tile) -> void:
	if is_solved:
		return
	if game_mode == Consts.GameMode.SWAP_VOID:
		if not move_in_progress:
			var void_tl: Tile = tile.get_void_neighbour()
			if void_tl:
				tile.swap_position_with_tile(void_tl, swap_time)
	
	else:  # SWAP_ANY
		if not move_in_progress:
			if tile == curr_tile:
				curr_tile.unselect()
				curr_tile = null
			elif not curr_tile or curr_tile.get_neighbours().find(tile) == -1:
				curr_tile = tile
				tile.select()
			else:
				tile.swap_position_with_tile(curr_tile, swap_time)
				curr_tile.unselect()
				curr_tile = null
			
			
func _on_tile_move_start(_tile: Tile) -> void:
	move_in_progress = true


func _on_tile_move_stop(tile: Tile) -> void:
	move_in_progress = false
	check_solved_status()


func setup() -> void:
	if play_music:
		AudioPlayer.play_music(AudioPlayer.MUSIC1, 0.03)
	set_bg_image(bg_image_path)
	set_tiles()
	EventBus.tile_clicked.connect(_on_tile_clicked)
	EventBus.tile_move_start.connect(_on_tile_move_start)
	EventBus.tile_move_stop.connect(_on_tile_move_stop)
	self.call_deferred(
		GAME_MODE_SETUP[game_mode]["shuffle_fn_name"],
		shuffle_count,
		shuffle_time
	)


func _ready() -> void:
	setup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
