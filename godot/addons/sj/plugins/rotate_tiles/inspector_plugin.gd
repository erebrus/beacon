@tool
extends EditorInspectorPlugin

# Do not use Vector2i(-INF/-INF) - will evaluate as equal to Vector2i(0,0)
const INVALID_COORDINATES := Vector2i(-1, -1)

const RECREATE_TILES_ID := 10

const RotatedTileData = preload("res://addons/sj/plugins/rotate_tiles/rotated_tile_data.gd")

var base_control : Control
var tile_set_editor : Node
var atlas_source_editor : Node
var tile_atlas_view : Node
var tileset_menu_button: MenuButton

# Proxy objects
# can get current source and selected tiles from their incoming connections
var atlas_source_proxy : Object
var atlas_tile_proxy : Object

func setup():
	base_control = EditorInterface.get_base_control()
	
	tile_set_editor = _get_first_node_by_class(base_control, "TileSetEditor")
	print("tile_set_editor=%s" % tile_set_editor)
	
	atlas_source_editor = _get_first_node_by_class(tile_set_editor, "TileSetAtlasSourceEditor")
	print("atlas_source_editor=%s" % atlas_source_editor)

	tile_atlas_view = _get_first_node_by_class(tile_set_editor, "TileAtlasView")
	print("tile_atlas_view=%s" % tile_atlas_view)

	atlas_source_proxy = _get_first_connected_object_by_class(atlas_source_editor, "TileSetAtlasSourceProxyObject")
	print("atlas_source_proxy=%s" % atlas_source_proxy)

	atlas_tile_proxy = _get_first_connected_object_by_class(atlas_source_editor, "AtlasTileProxyObject")
	print("atlas_tile_proxy=%s" % atlas_tile_proxy)
	
	var vbox = atlas_source_editor.get_child(1)
	print("vbox=%s" % vbox)
	
	var hbox = vbox.get_child(0)
	print("hbox=%s" % hbox)
	
	tileset_menu_button = _get_first_node_by_class(hbox, "MenuButton")
	print("menubutton=%s" % tileset_menu_button)
	
	var popup = tileset_menu_button.get_popup()
	popup.add_item("Recreate alternative tiles", RECREATE_TILES_ID)
	popup.id_pressed.connect(_on_menu_item_pressed)
	
	# TODO add option to recreate only one tile
	# TODO move/add button in the select tab instead of setup?
	

func _on_menu_item_pressed(id: int) -> void:
	if id == RECREATE_TILES_ID:
		_create_alternative_tiles()
	

# --------------------------------------
# 			CLEAN UP
# --------------------------------------

# Called from parent plugin when addon unloaded
func clean_up() -> void:
	var popup = tileset_menu_button.get_popup()
	var index = popup.get_item_index(RECREATE_TILES_ID)
	popup.remove_item(index)
	

# --------------------------------------
# 			GENERATE TILES
# --------------------------------------

func _create_alternative_tiles() -> void:
	print("recreating alternative tiles")
	var tileset = _get_current_tile_set()
	var source = _get_current_source()
	
	for i in source.get_tiles_count():
		var tile = source.get_tile_id(i)
		_create_alternative_tiles_for(tileset, source, tile)
	

func _create_alternative_tiles_for(tileset: TileSet, source: TileSetAtlasSource, tile: Vector2i) -> void:
	while source.get_alternative_tiles_count(tile) > 1:
		var id = source.get_alternative_tile_id(tile, 1)
		source.remove_alternative_tile(tile, id)
	
	var base_tile = RotatedTileData.new()
	base_tile.create(tileset, source, tile)
	
	var alt1 = base_tile.copy().rotate()
	var alt2 = alt1.copy().rotate()
	var alt3 = alt2.copy().rotate()
	

# --------------------------------------
# 	Helper functions
# --------------------------------------

func _get_current_tile_set() -> TileSet:
	return _get_first_connected_object_by_class(tile_set_editor, "TileSet")


func _get_current_source() -> TileSetAtlasSource:
	return _get_first_connected_object_by_class(atlas_source_proxy, "TileSetAtlasSource")


func _get_current_tiles(source : TileSetAtlasSource) -> Dictionary:
	var tiles := {}

	var tile_data_objects := _get_connected_objects_by_class(atlas_tile_proxy, "TileData")
	for tile_data in tile_data_objects:
		var coords := _find_coordinates_in_source(tile_data, source)
		if coords == INVALID_COORDINATES:
			push_error("Unable to find tile in source")
			return {}
		tiles[coords] = tile_data

	return tiles


func _find_coordinates_in_source(tile_data : TileData, source : TileSetAtlasSource) -> Vector2i:
	for i in range(source.get_tiles_count()):
		var coords := source.get_tile_id(i)
		if tile_data == source.get_tile_data(coords, 0):
			return coords
	return INVALID_COORDINATES


func _get_first_node_by_class(parent_node : Node, p_class_name : String) -> Node:
	var nodes := parent_node.find_children("*", p_class_name, true, false)
	if !nodes.size():
		return null
	return nodes[0]


func _get_first_connected_object_by_class(object : Object, p_class_name : String) -> Object:
	var objects := _get_connected_objects_by_class(object, p_class_name)
	if !objects.size():
		return null
	return objects[0]


func _get_connected_objects_by_class(object : Object, p_class_name : String) -> Array:
	var objects := []
	for connection in object.get_incoming_connections():
		var connected_object = connection["signal"].get_object()
		if connected_object.is_class(p_class_name):
			objects.append(connected_object)
	return objects
