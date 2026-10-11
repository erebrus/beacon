class_name GroundTileMap extends TileMapLayer

@export var fog_of_war_radius: int = 2


var visited_source_id: int
var unvisited_source_id: int


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
