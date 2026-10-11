class_name GroundTileMap extends TileMapLayer

@export var fog_of_war_radius: int = 2


var visited_source_id: int
var unvisited_source_id: int

var objects: Dictionary[Vector2i, TileComponent]

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
	# TODO: changes untested
	var obj: TileComponent = objects[cell] if cell in objects else null
	
	if obj and obj.exclusive_cell_use:
		return false
	
	return true

# TODO: replace by get_object
func has_interaction(cell: Vector2i) -> bool:
	return false #TODO missing

func get_object(cell: Vector2i) -> Node:
	if not objects.has(cell):
		return null
	return objects[cell].target


# TODO: replace by register_component
func register_object(obj:Node2D) -> void:
	var cell :Vector2i = obj.current_cell
	
	var component:= TileComponent.new()
	component.cell = cell
	component.target = obj
	obj.add_child(component)
	
	register_component(component)


func register_component(component: TileComponent) -> void:
	var cell:= global_to_map(component.global_position)
	if objects.has(cell):
		GSLogger.error("Object %s cannot be registered in map. Cell %s already taken." % [component.target.name, component.cell])
		return
	component.cell = cell
	objects[cell] = component
	
	component.tree_exiting.connect(func(): 
		if objects.has(component.cell) and objects[component.cell] == component:
			objects.erase(cell)
	)
	
	GSLogger.info("Object %s registered at %s" % [component.target.name, component.cell])


func move_component(component: TileComponent, new_cell: Vector2i) -> bool:
	if objects.has(component.cell) and objects[component.cell] == component:
		if is_cell_free(new_cell):
			objects.erase(component.cell)
			var old_cell := component.cell
			component.cell = new_cell
			objects[new_cell] = component
			GSLogger.debug("Moved object %s from %s to %s" % [component.target.name, old_cell, new_cell])
			return true
		else:
			GSLogger.warn("Tried to move object %s from %s to %s, but it's not empty!." % [component.target.name, component.cell, new_cell])
			return false
	else:
		GSLogger.warn("Tried to move object %s from %s to %s, but it's not there!." % [component.target.name, component.cell, new_cell])
		return false


# TODO: replace by move_component
func move_object(old_cell:Vector2i, new_cell: Vector2i) -> bool:
	if old_cell in objects:
		return move_component(objects[old_cell], new_cell)
	else:
		GSLogger.warn("Tried to move object from %s to %s, but no object found." % [old_cell, new_cell])
		return false
