extends Node2D

@onready var terrain: TileMapLayer = $Terrain

var walls: Array[Vector2i]
var quacker: Quacker

var level_size: Vector2
var tile_size: Vector2 = Vector2(64, 64);


func _ready():
	level_size = terrain.get_used_rect().size
	walls = terrain.get_used_cells_by_id(0)
	var quacker_tile_coord = terrain.get_used_cells_by_id(1)[0]
	terrain.set_cell(quacker_tile_coord, -1)  # Set to -1 to remove the tile
	var quacker_world_position = tile_to_world(quacker_tile_coord)
	quacker = Quacker.summonQuacker()
	quacker.global_position = quacker_world_position
	get_parent().add_child.call_deferred(quacker)

func _input(event):
	if not(event is InputEventKey and event.pressed):
		return
		
	if event.is_action("up"):
		quackerMove(Vector2.UP)
	elif event.is_action("down"):
		quackerMove(Vector2.DOWN)
	elif event.is_action("left"):
		quackerMove(Vector2.LEFT)
	elif event.is_action("right"):
		quackerMove(Vector2.RIGHT)


func quackerMove(direction: Vector2i):
	var anyMoved = false;
	var tile_coords = world_to_tile(quacker.position)
	var target = tile_coords + direction
	if target in walls:
		return false
	else:
		var target_in_world = tile_to_world(target)
		var moved = quacker.move(target_in_world)
		if moved:
			anyMoved = true;


### Utility
func restart_level():
	var t = get_tree()
	if t:
		t.reload_current_scene()
	else:
		pass

func world_to_tile(world_pos: Vector2):
	var local = terrain.to_local(world_pos)
	var tile = terrain.local_to_map(local)
	return tile

func tile_to_world(tile_coords: Vector2):
	var local = terrain.map_to_local(tile_coords)
	var global = terrain.to_global(local)
	return global
