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


func visit(center_cell: Vector2i) -> void:
	for x in range(center_cell.x - fog_of_war_radius, center_cell.x + fog_of_war_radius):
		for y in range(center_cell.y - fog_of_war_radius, center_cell.y + fog_of_war_radius):
			var cell:= Vector2i(x,y)
			if get_cell_source_id(cell) == unvisited_source_id:
				_reveal(cell)


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
	if get_cell_source_id(cell) < 0:
		return false
	
	var obj: TileComponent = objects[cell] if cell in objects else null
	
	if obj and obj.exclusive_cell_use:
		return false
	
	return true


func can_interact(cell: Vector2i) -> bool:
	if not objects.has(cell):
		return false
	return objects[cell].can_interact


func interact(cell: Vector2i) -> void:
	if not objects.has(cell):
		GSLogger.warn("Tried to interact with object at %s, but it's not interactionable!." % [cell])
		return
	
	var component:= objects[cell]
	if not component.can_interact:
		GSLogger.warn("Tried to interact with object %s at %s, but it's not interactionable!." % [component.target.name, cell])
		return
	
	component.interact()


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
	if get_cell_source_id(new_cell) < 0:
		GSLogger.warn("Tried to move object %s from %s to %s, but it's out of the map!." % [component.target.name, component.cell, new_cell])
		return false
	
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
