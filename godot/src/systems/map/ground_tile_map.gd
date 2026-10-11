class_name GroundTileMap extends TileMapLayer

@export var fog_of_war_radius: int = 2


var visited_source_id: int
var unvisited_source_id: int

var objects:Dictionary[Vector2i, Node2D]

func _ready() -> void:
	for i in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(i)
		var source := tile_set.get_source(source_id)
		match source.resource_name:
			"visited":
				visited_source_id = source_id
			"unvisited":
				unvisited_source_id = source_id


func visit(center_cell: Vector2i) -> bool:
	if get_cell_source_id(center_cell) < 0:
		return false
	
	for x in range(center_cell.x - fog_of_war_radius, center_cell.x + fog_of_war_radius):
		for y in range(center_cell.y - fog_of_war_radius, center_cell.y + fog_of_war_radius):
			var cell:= Vector2i(x,y)
			if get_cell_source_id(cell) == unvisited_source_id:
				_reveal(cell)
	return true


func is_visited(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) == visited_source_id


func _reveal(cell: Vector2i) -> void:
	set_cell(cell, visited_source_id, get_cell_atlas_coords(cell), get_cell_alternative_tile(cell))


func global_to_map(position: Vector2) -> Vector2i:
	var local := position - global_position
	return local_to_map(local)
	
func map_to_global(cell:Vector2i) -> Vector2:
	return map_to_local(cell) + global_position

func is_cell_free(cell: Vector2i) -> bool:
	return true #TODO missing

func has_interaction(cell: Vector2i) -> bool:
	return false #TODO missing

func register_object(obj:Node2D) -> void:
	var cell :Vector2i = obj.current_cell
	

	if objects.has(cell):
		GSLogger.error("Object %s cannot be registered in map. Cell %s already taken." % [obj.name, obj.current_cell])
		return
	objects[cell] = obj
	GSLogger.info("Object %s registered at %s" % [obj.name, cell])

func move_object(old_cell:Vector2i, new_cell: Vector2i) -> bool:
	
	var obj = objects[old_cell]
	if old_cell in objects:
		if new_cell in objects:
			GSLogger.warn("Can't move object %s in map from %s to %s. Cell not empty."  % [obj.name, old_cell, new_cell])
			return false
		else:
			objects.erase(old_cell)
			objects[new_cell] = obj
			GSLogger.debug("Moved object %s from %s to %s" % [obj.name, old_cell, new_cell])
			return true
	else:
		GSLogger.warn("Tried to move object from %s to %s, but no object found." % [old_cell, new_cell])
		return false
		
	
	
