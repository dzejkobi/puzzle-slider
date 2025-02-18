class_name Tile
extends Node2D

@onready var coll_shape: CollisionShape2D = $Area/CollShape
@onready var bg_rect: ColorRect = $BGRect
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

var is_hovered: bool = false:
	get:
		return is_hovered
	set(value):
		if value != is_hovered:
			selection.visible = value
			is_hovered = value


func resize(new_size: Vector2i):
	size = new_size
	coll_shape.shape.size = new_size
	bg_rect.size = Vector2i(
		new_size.x - 2 * padding,
		new_size.y - 2 * padding
	)
	bg_rect.position = Vector2i(
		-new_size.x / 2	+ padding,
		-new_size.y / 2 + padding
	)
	selection.size = new_size
	selection.position = -new_size / 2
	label.add_theme_font_size_override("font_size", int(new_size.y * 0.6))
	
	up_ray.target_position = Vector2i(0, -size.y)
	right_ray.target_position = Vector2i(size.x, 0)
	down_ray.target_position = Vector2i(0, size.y)
	left_ray.target_position = Vector2i(-size.x, 0)
	
	
func setup(params: Dictionary = {}) -> void:
	"""
	params:
		ordinal: int,
		size: Vector2i,
		position: Vector2i,
		show_label: bool,
		bg_color: Color,
		is_void: bool
	"""
	ordinal = params.get("ordinal")
	if "size" in params.keys():
		resize(params.size)
	if "position" in params.keys():
		position = params.position
	if params.get("show_label"):
		label.text = str(ordinal)
		label.visible = true
	if params.get("bg_color"):
		var bg_color: Color = params.bg_color
		bg_rect.visible = true
		bg_rect.color = bg_color
	is_void = params.get("is_void", false)
	if is_void:
		label.visible = false
		bg_rect.visible = false


func get_void_neighbour() -> Tile:
	for ray: RayCast2D in neighbour_rays:
		if ray.is_colliding():
			var neighbour = ray.get_collider()
			if neighbour:
				var parent = neighbour.get_parent()
				if parent is Tile and parent.is_void:
					return parent
	return null


func swap_position_with_tile(tile: Tile) -> void:
	var pos = self.position
	self.position = tile.position
	tile.position = pos


func _process(delta: float) -> void:
	pass


func _on_area_mouse_shape_entered(shape_idx: int) -> void:
	if not is_void:
		is_hovered = true


func _on_area_mouse_shape_exited(shape_idx: int) -> void:
	is_hovered = false


func _on_area_input_event(
	viewport: Node, event: InputEvent, shape_idx: int
) -> void:
	if (
		event is InputEventMouseButton and
		Input.is_action_just_pressed('left_mouse_btn')
	):
		EventBus.tile_clicked.emit(self)
