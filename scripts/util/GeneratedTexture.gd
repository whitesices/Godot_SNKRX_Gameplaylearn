class_name GeneratedTexture
extends RefCounted

static func load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path, "Texture2D"):
		var resource: Resource = ResourceLoader.load(path, "Texture2D")
		if resource is Texture2D:
			return resource as Texture2D
	var absolute_path: String = ProjectSettings.globalize_path(path)
	var image: Image = Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)
