class_name EndlessLevelManager
extends LevelManager

func _ready():
	level_size = terrain.get_used_rect().size
	level_offset = terrain.get_used_rect().position
	
	Singleton.restart.connect(self.restart_level)
	
	inputDelayTimer.set_wait_time(Global.TICK_DURATION / 2)
	
	inputDelayTimer.timeout.connect(alternate_cycle_update)
	
	
	parse_tilemaplayer()
	
	Singleton.lose.connect(lose_handler)

var parity = 1
func alternate_cycle_update():
	if parity > 0:
		endless_drop_random_tiles()
	else:
		handle_input()
	parity *= -1



# Endless extras
var ticks_since_last_tile = 0
const TICKS_UNTIL_NEXT_TILE = 3
func endless_drop_random_tiles():
	# quacker offmap
	var tile_coords = world_to_tile(quacker.position) - level_offset
	if tile_coords.x < 2 or tile_coords.x > level_size.x - 3 or tile_coords.y < 2 or tile_coords.y > level_size.y - 3:
		quacker.die()
	
	# remove edge crates
	for i in range(level_size.y):
		if crate_coord_array[i][1] is Crate:
			var c = crate_coord_array[i][1]
			crate_coord_array[i][1] = 0
			for j in range(crates.size()):
				if crates[j] == c:
					crates.remove_at(j)
					break
			c.queue_free()
		if crate_coord_array[i][level_size.x - 2] is Crate:
			var c = crate_coord_array[i][level_size.x - 2]
			crate_coord_array[i][level_size.x - 2] = 0
			for j in range(crates.size()):
				if crates[j] == c:
					crates.remove_at(j)
					break
			c.queue_free()
	for i in range(level_size.y):
		if crate_coord_array[1][i] is Crate:
			var c = crate_coord_array[1][i]
			crate_coord_array[1][i] = 0
			for j in range(crates.size()):
				if crates[j] == c:
					crates.remove_at(j)
					break
			c.queue_free()
		if crate_coord_array[level_size.y - 2][i] is Crate:
			var c = crate_coord_array[level_size.y - 2][i]
			crate_coord_array[level_size.y - 2][i] = 0
			for j in range(crates.size()):
				if crates[j] == c:
					crates.remove_at(j)
					break
			c.queue_free()
	
	
	ticks_since_last_tile += 1
	if ticks_since_last_tile >= TICKS_UNTIL_NEXT_TILE:
		ticks_since_last_tile = 0
		#drop item
		var item = endless_choose_random_item()
		var item_coords = endless_choose_random_coords()
		print(item_coords)
		item.global_position = tile_to_world(item_coords)
		add_child.call_deferred(item)
		if item is Egg:
			eggs.append(item)
		if item is Crate:
			crates.append(item)
			crate_coord_array[item_coords.y - level_offset.y][item_coords.x - level_offset.x] = item
		terrain.set_cell(item_coords, -1)

# Egg, Block
func endless_choose_random_item():
	#match randi_range(0, 1):
		#0: 
			#return Egg.summonEgg()
		#1:
			#return Crate.summonCrate()
	if randi_range(0, 2) == 0:
		# 1/3 chance
		return Egg.summonEgg()
	# 2/3 chance
	return Crate.summonCrate()

func endless_choose_random_coords():
	var choice_array = []
	for i in range(2, level_size.y - 2):
		for j in range(2, level_size.x - 2):
			if crate_coord_array[i][j] is Crate:
				continue
			for egg in eggs:
				if tile_to_world(Vector2(j, i)) == egg.global_position:
					continue
			for duck in ducklings:
				if tile_to_world(Vector2(j, i)) == duck.global_position:
					continue
			choice_array.append([i, j])
	var chosen = choice_array.pick_random()
	return Vector2(chosen[1] + level_offset.x, chosen[0] + level_offset.y)
