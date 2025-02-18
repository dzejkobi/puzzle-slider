extends Node2D

@export var tile_amount: Vector2i = Vector2i(4, 4)
@export var game_mode: Consts.GameMode = Consts.GameMode.SWAP_VOID

@onready var coll_shape: CollisionShape2D = $Area/CollShape

var tile_scene = preload('res://tile/tile.tscn')


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
			ordinal += 1


func _on_tile_clicked(tile: Tile) -> void:
	var void_tile: Tile = tile.get_void_neighbour()
	if void_tile:
		tile.swap_position_with_tile(void_tile)


func setup() -> void:
	set_tiles()
	EventBus.tile_clicked.connect(_on_tile_clicked)


func _ready() -> void:
	setup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
