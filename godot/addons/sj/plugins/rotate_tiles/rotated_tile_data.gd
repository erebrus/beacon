extends RefCounted


enum TerrainBits {
	#CENTER,
	TOP_LEFT_CORNER,
	TOP_SIDE,
	TOP_RIGHT_CORNER,
	RIGHT_SIDE,
	BOTTOM_RIGHT_CORNER,
	BOTTOM_SIDE,
	BOTTOM_LEFT_CORNER,
	LEFT_SIDE,
}

const RotatedTileData = preload("res://addons/sj/plugins/rotate_tiles/rotated_tile_data.gd")

const TERRAIN_NEIGHBORS = {
	#TerrainBits.CENTER: 99,
	TerrainBits.TOP_LEFT_CORNER: TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TerrainBits.TOP_SIDE: TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TerrainBits.TOP_RIGHT_CORNER: TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TerrainBits.RIGHT_SIDE: TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	TerrainBits.BOTTOM_RIGHT_CORNER: TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TerrainBits.BOTTOM_SIDE: TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TerrainBits.BOTTOM_LEFT_CORNER: TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TerrainBits.LEFT_SIDE: TileSet.CELL_NEIGHBOR_LEFT_SIDE,
}

var tileset: TileSet
var source: TileSetAtlasSource
var tile: Vector2i
var rotation: int = 0


func create(_tileset: TileSet, _source: TileSetAtlasSource, _tile: Vector2i) -> void:
	tileset = _tileset
	source = _source
	tile = _tile
	

func copy() -> RotatedTileData:
	var rotated = RotatedTileData.new()
	rotated.tileset = tileset
	rotated.source = source
	rotated.tile = tile
	rotated.rotation = rotation
	
	return rotated
	

func rotate() -> RotatedTileData:
	rotation += 1
	print("Creating alternative %s:%s" % [tile, rotation])
	
	source.create_alternative_tile(tile, rotation)
	var base_data = source.get_tile_data(tile, rotation - 1)
	var data = source.get_tile_data(tile, rotation)
	
	# TODO: Animation
	
	# Rendering
	data.flip_h = rotation > 1
	data.flip_v = rotation < 3
	data.transpose =  rotation % 2 == 1
	
	data.texture_origin = base_data.texture_origin
	data.modulate = base_data.modulate
	data.material = base_data.material
	data.z_index = base_data.z_index
	data.y_sort_origin = base_data.y_sort_origin
	
	# TERRAINS
	data.terrain_set = base_data.terrain_set
	data.terrain = base_data.terrain
	
	for old_bit: TerrainBits in TerrainBits.values():
		var old_neighbor: TileSet.CellNeighbor = TERRAIN_NEIGHBORS[old_bit]
		if base_data.is_valid_terrain_peering_bit(old_neighbor):
			var terrain = base_data.get_terrain_peering_bit(old_neighbor)
			var new_bit = _rotate_peering_bit(old_bit)
			var new_neighbor =  TERRAIN_NEIGHBORS[new_bit]
			data.set_terrain_peering_bit(new_neighbor, terrain)
		
	
	# MISCELLANEOUS
	data.probability = base_data.probability
	
	# PHYSICS LAYERS
	for layer in tileset.get_physics_layers_count():
		var linear_velocity = base_data.get_constant_linear_velocity(layer)
		data.set_constant_linear_velocity(layer, linear_velocity)
		
		var angular_velocity = base_data.get_constant_angular_velocity(layer)
		data.set_constant_angular_velocity(layer, angular_velocity)
		
		for polygon in base_data.get_collision_polygons_count(layer):
			var one_way = base_data.is_collision_polygon_one_way(layer, polygon)
			var one_way_margin = base_data.get_collision_polygon_one_way_margin(layer, polygon)
			var points = base_data.get_collision_polygon_points(layer, polygon)
			
			data.add_collision_polygon(layer)
			data.set_collision_polygon_one_way(layer, polygon, one_way_margin)
			data.set_collision_polygon_one_way(layer, polygon, one_way)
			data.set_collision_polygon_points(layer, polygon, _rotate_polygon(points))
		
	
	# TODO: Occlusion Layer
	# TODO: Navigation
	# TODO: Custom data
	
	return self
	

func _rotate_peering_bit(bit: TerrainBits) -> TerrainBits:
	match bit:
		TerrainBits.TOP_LEFT_CORNER:
			return TerrainBits.BOTTOM_LEFT_CORNER
		TerrainBits.BOTTOM_LEFT_CORNER:
			return TerrainBits.BOTTOM_RIGHT_CORNER
		TerrainBits.BOTTOM_RIGHT_CORNER:
			return TerrainBits.TOP_RIGHT_CORNER
		TerrainBits.TOP_RIGHT_CORNER:
			return TerrainBits.TOP_LEFT_CORNER
		TerrainBits.TOP_SIDE:
			return TerrainBits.LEFT_SIDE
		TerrainBits.LEFT_SIDE:
			return TerrainBits.BOTTOM_SIDE
		TerrainBits.BOTTOM_SIDE:
			return TerrainBits.RIGHT_SIDE
		TerrainBits.RIGHT_SIDE:
			return TerrainBits.TOP_SIDE
		_:
			print("Unknown neighbor %s" % bit)
			return 0
			#return TerrainBits.CENTER
	

func _rotate_polygon(polygon: PackedVector2Array) -> PackedVector2Array:
	var points: Array[Vector2]
	for point: Vector2 in Array(polygon):
		points.append(point.rotated(-PI / 2))
	
	return PackedVector2Array(points)
