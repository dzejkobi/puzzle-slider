extends Node2D

@export var tile_amount: Vector2i = Vector2i(4, 4)
@export var game_mode: Consts.GameMode = Consts.GameMode.SWAP_VOID
@export var swap_time: float = 0.1

@onready var coll_shape: CollisionShape2D = $Area/CollShape

var tile_scene = preload('res://tile/tile.tscn')
var move_in_progress: bool = false
var void_tile: Tile


func get_tiles() -> Array[Tile]:
	var result: Array[Tile] = []
	result.assign(get_tree().get_nodes_in_group('tile'))
	return result
	

func set_tiles() -> void:
	for tile: Node in get_tiles():
		tile.queue_free()
	
	var tile_size: = Vector2i(
		roundi(coll_shape.shape.size.x / tile_amount.x),
		roundi(coll_shape.shape.size.y / tile_amount.y)
	)
	var tile: Tile
	var board_tl: = Vector2i(
		coll_shape.position - coll_shape.shape.size / 2
	)
	
	var ordinal: = 1
	var last_ordinal: = tile_amount.x * tile_amount.y
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
				"show_label": true,
				"ordinal": ordinal,
				"bg_color": Color.DARK_CYAN,
				"is_void": (
					ordinal == last_ordinal and
					game_mode == Consts.GameMode.SWAP_VOID
				)
			})
			if tile.is_void:
				void_tile = tile
			ordinal += 1


func shuffle_tiles(n_swaps: int, swap_time: float) -> void:
	var neighbours: Array[Tile]
	var tile_to_swap: Tile
	var last_tile: Tile
	var last_tile_index: int
	for i: int in range(n_swaps):
		neighbours = void_tile.get_neighbours()
		last_tile_index = neighbours.find(last_tile)
		if last_tile_index > -1:
			# do not reverse the last swap
			neighbours.remove_at(last_tile_index)
		tile_to_swap = neighbours[randi_range(0, len(neighbours) - 1)]
		void_tile.swap_position_with_tile(tile_to_swap, swap_time)
		last_tile = tile_to_swap
		await EventBus.tile_move_stop
		

func _on_tile_clicked(tile: Tile) -> void:
	if not move_in_progress:
		var void_tile: Tile = tile.get_void_neighbour()
		if void_tile:
			tile.swap_position_with_tile(void_tile, swap_time)
			
			
func _on_tile_move_start(tile: Tile) -> void:
	move_in_progress = true


func _on_tile_move_stop(tile: Tile) -> void:
	move_in_progress = false


func setup() -> void:
	set_tiles()
	EventBus.tile_clicked.connect(_on_tile_clicked)
	EventBus.tile_move_start.connect(_on_tile_move_start)
	EventBus.tile_move_stop.connect(_on_tile_move_stop)
	self.call_deferred("shuffle_tiles", 100, 0.03)


func _ready() -> void:
	setup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
