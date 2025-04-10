extends Script

class_name Graphics


static func crop_image(src_img: Image, max_size: Vector2i) -> Image:
	"""
	Crops contents of src_img to fit given size
	and returns the new cropped image.
	"""
	var src_size: = src_img.get_size()
	var cropped_size: = Vector2i(
		src_size.x if src_size.x < max_size.x else max_size.x,
		src_size.y if src_size.y < max_size.y else max_size.y
	)
	var crop_rect: = Rect2i(
		Vector2i(
			(src_size.x - cropped_size.x) / 2,
			(src_size.y - cropped_size.y) / 2,
		),
		cropped_size
	)
	var cropped_img: = Image.create(
		cropped_size.x, cropped_size.y, false, src_img.get_format()
	)
	cropped_img.blit_rect(src_img, crop_rect, Vector2.ZERO)
	return cropped_img
	
	
static func make_rect_image(src_img: Image) -> Image:
	var orig_size: Vector2i = src_img.get_size()
	var new_dim: int = orig_size.x if orig_size.x < orig_size.y else orig_size.y
	var new_size: = Vector2i(new_dim, new_dim)
	return crop_image(src_img, new_size)
	
