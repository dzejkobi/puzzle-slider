class_name Tile
extends Node2D

@onready var coll_shape: CollisionShape2D = $Area/CollShape
@onready var bg_rect: ColorRect = $BGRect
@onready var tex_rect: TextureRect = $TexRect
@onready var match_rect: ColorRect = $MatchRect
@onready var selection: ReferenceRect = $Selection
@onready var label: Label = $Label

@onready var up_ray: RayCast2D = $Area/UpRay
@onready var right_ray: RayCast2D = $Area/RightRay
@onready var down_ray: RayCast2D = $Area/DownRay
@onready var left_ray: RayCast2D = $Area/LeftRay
@onready var neighbour_rays: Array[RayCast2D] = [
	up_ray, right_ray, down_ray, left_ray
]

@export var ordinal: int
@export var size: Vector2i = Vector2i(60, 60)
@export var padding: int = 4
@export var is_void: bool = false
@export var grid_position: Vector2i
@export_color_no_alpha var hover_color: = Color('ff9d00')
@export_color_no_alpha var selection_color: = Color('ff0000')

var moving_to: Vector2
var matching_pos: Vector2


var is_hovered: bool = false:
	get:
		return is_hovered
	set(value):
		if value != is_hovered:
			if value:
				selection.visible = true
				selection.border_color = hover_color
			elif is_selected:
				selection.border_color = selection_color
			else:
				selection.visible = false
			is_hovered = value


var is_selected: bool = false


func select():
	selection.visible = true
	selection.border_color = selection_color
	is_selected = true
	EventBus.tile_selected.emit(self)
	
	
func unselect():
	if not is_hovered:
		selection.visible = false
	else:
		selection.border_color = hover_color
	is_selected = false


func is_matching():
	return position == matching_pos
	
	
@warning_ignore("integer_division")
func resize(new_size: Vector2i):
	size = new_size
	coll_shape.shape.size = new_size
	bg_rect.size = Vector2i(
		new_size.x - 2 * padding,
		new_size.y - 2 * padding
	)
	tex_rect.size = bg_rect.size
	match_rect.size = Vector2i(
		new_size.x - 4 * padding,
		new_size.y - 4 * padding
	)
	bg_rect.position = Vector2i(
		-new_size.x / 2 + padding,
		-new_size.y / 2 + padding
	)
	tex_rect.position = bg_rect.position 
	match_rect.position = Vector2i(
		-new_size.x / 2 + 2 * padding,
		-new_size.y / 2 + 2 * padding
	)
	selection.size = new_size
	selection.position = -new_size / 2
	label.add_theme_font_size_override("font_size", int(new_size.y * 0.6))
	
	up_ray.target_position = Vector2i(0, -size.y)
	right_ray.target_position = Vector2i(size.x, 0)
	down_ray.target_position = Vector2i(0, size.y)
	left_ray.target_position = Vector2i(-size.x, 0)


func set_tile_image(bg_image: Image) -> void:
	var tile_bg_img: = Image.create(
		size.x - 2 * padding, size.y - 2 * padding, false, bg_image.get_format()
	)
	tile_bg_img.blit_rect(
		bg_image,
		Rect2i(
			Vector2i(
				grid_position.x * size.x + padding,
				grid_position.y * size.y + padding
			),
			Vector2i(size.x - 2 * padding, size.y - 2 * padding)
		),
		Vector2i.ZERO
	)
	tex_rect.texture = ImageTexture.create_from_image(tile_bg_img)

	
func setup(params: Dictionary = {}) -> void:
	"""
	params:
		ordinal: int,
		size: Vector2i,
		position: Vector2i,
		show_label: bool,
		bg_color: Color,
		bg_texture: ImageTexture,
		is_void: bool
	"""
	EventBus.tile_move_stop.connect(_on_tile_move_stop)
	EventBus.tile_selected.connect(_on_tile_selected)

	ordinal = params.get("ordinal")
	if "size" in params.keys():
		resize(params.size)
	if "position" in params.keys():
		position = params.position
		matching_pos = position
	if "grid_position" in params.keys():
		grid_position = params.grid_position
	if params.get("show_label"):
		label.text = str(ordinal)
		label.visible = true
	if params.get("bg_color"):
		var bg_color: Color = params.bg_color
		bg_rect.visible = true
		bg_rect.color = bg_color
	if params.get("bg_image"):
		var bg_image: Image = params.bg_image
		set_tile_image(bg_image)
	is_void = params.get("is_void", false)
	if is_void:
		label.visible = false
		bg_rect.visible = false
		tex_rect.visible = false


func get_neighbour(ray: RayCast2D) -> Tile:
	if ray.is_colliding():
		var neighbour = ray.get_collider()
		if neighbour:
			var parent = neighbour.get_parent()
			if parent is Tile:
				return parent
	return null


func get_neighbours(exclude_void: bool = true) -> Array[Tile]:
	var neighbours: Array[Tile] = []
	var neighbour: Tile
	for ray: RayCast2D in neighbour_rays:
		neighbour = get_neighbour(ray)
		if neighbour and not (exclude_void and neighbour.is_void):
			neighbours.append(neighbour)
	return neighbours


func get_void_neighbour() -> Tile:
	var neighbour: Tile
	for ray: RayCast2D in neighbour_rays:
		neighbour = get_neighbour(ray)
		if neighbour and neighbour.is_void:
			return neighbour
	return null


func swap_position_with_tile(
	tile: Tile, time: float, play_sound: bool = true
) -> void:
	EventBus.tile_move_start.emit(self)
	moving_to = tile.position
	tile.moving_to = position
	if play_sound:
		AudioPlayer.play_sfx(
			AudioPlayer.pick_sound_at_random(AudioPlayer.SHUFFLES_SFX), 0.5
		)
	var move_tween_1 = get_tree().create_tween()
	move_tween_1.tween_property(self, "position", tile.position, time)
	move_tween_1.tween_callback(EventBus.tile_move_stop.emit.bind(self))
	var move_tween_2 = get_tree().create_tween()
	move_tween_2.tween_property(tile, "position", self.position, time)
	move_tween_2.tween_callback(EventBus.tile_move_stop.emit.bind(tile))


func _process(_delta: float) -> void:
	pass


func _on_area_mouse_shape_entered(_shape_idx: int) -> void:
	if not is_void:
		is_hovered = true


func _on_area_mouse_shape_exited(_shape_idx: int) -> void:
	is_hovered = false
	
	
func _on_tile_selected(tile: Tile) -> void:
	if tile != self:
		# Only one tile can be selected at the time
		unselect()


func _on_area_input_event(
	_viewport: Node, event: InputEvent, _shape_idx: int
) -> void:
	if (
		event is InputEventMouseButton and
		Input.is_action_just_pressed('left_mouse_btn')
	):
		EventBus.tile_clicked.emit(self)


func _on_tile_move_stop(tile: Tile) -> void:
	# ensure that the exact target postion is reached
	if tile == self:
		tile.position = tile.moving_to
		match_rect.visible = tile.is_matching() and not tile.is_void
