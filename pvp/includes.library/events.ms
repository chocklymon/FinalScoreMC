# The assign() functions in the event binds are required to keep the instances from interfering with each other
# Just passing the variable (eg. ", @pvp['arena'], @id,") did not work last I tested
array_push(@pvp['binds'], @id.'death')
bind('player_death', array('priority': 'high', 'id': @id.'death'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), 
		die())

	if(@pvp['arena']['mode'] != 'ctf' && !array_index_exists(@pvp['arena'], 'captain')) {
		@deathmessage = @e['death_message']
		
		@pcolor = ''
		if(array_index_exists(@pvp['arena'], 'team')) {
			@pcolor = color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color'])
		}
		
		if(@e['cause']['cause'] == 'BLOCK_EXPLOSION'
		&& !array_index_exists(@e['cause'], 'damager')) {
			@deathmessage = @pcolor.player().color('r').' got blown up'
		
		} else if(@e['cause']['cause'] == 'CUSTOM') {
			@deathmessage = @pcolor.player().color('r').' died'
		
		} else if(array_index_exists(@pvp['arena'], 'team')) {
			@parts = parse_args(@e['death_message'])
			@parts[0] = @pcolor.player().color('r')
			if(array_index_exists(@pvp['players'], @e['killer'])) {
				@kcolor = color(@pvp['arena']['team'][@pvp['players'][@e['killer']]['team']]['color'])
				for(@i = 1, @i < array_size(@parts), @i++) {
					if(@parts[@i] == @e['killer']) {
						@parts[@i] = @kcolor.@e['killer'].color('r')
					}
				}
			}
			@deathmessage = array_implode(@parts)
		}
		
		_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color('r').@deathmessage)
	}
	
	@pvp['stats'][player()]['deaths'] += 1
	if(array_index_exists(@pvp['players'], @e['killer'])) {
		@pvp['stats'][@e['killer']]['kills'] += 1
	}
	@totaldamage = 20
	@damagers = array()
	for(@i = array_size(@pvp['stats'][player()]['damagetaken']) - 1, @i >= 0 && @totaldamage > 0, @i--) {
		@totaldamage -= @pvp['stats'][player()]['damagetaken'][@i][1]
		if(@pvp['stats'][player()]['damagetaken'][@i][0] != @e['killer']
		&& !array_contains(@damagers, @pvp['stats'][player()]['damagetaken'][@i][0])) {
			@pvp['stats'][@pvp['stats'][player()]['damagetaken'][@i][0]]['assists'] += 1
			array_push(@damagers, @pvp['stats'][player()]['damagetaken'][@i][0])
		}
	}
	@pvp['stats'][player()]['damagetaken'] = array()

	if(array_index_exists(@pvp['arena'], 'lives')) {
		@pvp['players'][player()]['lives'] = @pvp['players'][player()]['lives'] - 1
		if(array_contains(array('tdm', 'dm'), @pvp['arena']['mode'])) {
			set_pscore('lives', player(), @pvp['players'][player()]['lives'], @id)
		}
	} else if(@pvp['arena']['mode'] == 'infection' && @pvp['players'][player()]['team'] == 0) {
		team_remove_player(@pvp['arena']['team'][@pvp['players'][player()]['team']]['name'], player(), @id)
		array_remove_values(@pvp['team'][0]['players'], player())
		@pvp['players'][player()]['team'] = 1
		team_add_player(@pvp['arena']['team'][1]['name'], player(), @id)
		if(array_index_exists(@pvp['arena'], 'classes')) {
			if(array_index_exists(@pvp['players'][player()], 'class')) {
				_class('unload', player(), @pvp['players'][player()]['class'])
				array_remove(@pvp['players'][player()], 'class')
			}
			if(array_size(@pvp['arena']['classes'][@pvp['players'][player()]['team']]) > 0) {
				@pvp['players'][player()]['class'] = @pvp['arena']['classes'][1][0]
				_class('load', player(), @pvp['players'][player()]['class'])
			}
		}
	}
	set_timeout(5000, closure(){
		if(pinfo(player(), 5) <= 0) {
			if(function_exists('respawn')) {
				respawn(player())
			}
		}
	})

	if(array_index_exists(@pvp['arena'], 'lives')) {
		if(@pvp['players'][player()]['lives'] == 0) {
			if(array_index_exists(@pvp['players'][player()], 'class')) {
				_class('unload', player(), @pvp['players'][player()]['class'])
			}
			if(array_index_exists(@pvp['arena'], 'timer') && phas_bar()) {
				premove_bar()
			}
			array_remove(@pvp['players'], player())
		}
	}
	
	if(array_index_exists(@pvp['arena'], 'respawntime')) {
		@pvp['players'][player()]['respawn'] = time() + (@pvp['arena']['respawntime'] * 1000)
	}
	
	if(array_contains(@pvp['arena']['flags'], 'keepinventory')) {
		@pvp['players'][player()]['inv'] = pinv()
	}

	@drops = array()
	foreach(@e['drops'], @drop) {
		if(@pvp['arena']['mode'] == 'ctf' && (@drop['type'] == 8 || @drop['type'] == 10)) {
			_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color'])
				.player().color('r').' dropped the '.color(@pvp['arena']['team'][if(@pvp['players'][player()]['team'] == 0, 1, 0)]['color']).'flag')
			if(@e['cause']['cause'] == 'VOID' || @e['cause']['cause'] == 'LAVA') {
				_pvp_flag_spawn(@id, if(@drop['type'] == 10, 0, 1))
			} else {
				_pvp_flag_spawn(@id, if(@drop['type'] == 10, 0, 1), _relative(ploc(), 'up'))
			}
		} else if(array_index_exists(@pvp['arena'], 'captain') 
		&& @drop['type'] == @pvp['team'][@pvp['players'][player()]['team']]['captainhat']['type']
		&& (max_stack_size(@pvp['team'][@pvp['players'][player()]['team']]['captainhat']['type']) == 1
		|| @drop['data'] == @pvp['team'][@pvp['players'][player()]['team']]['captainhat']['data'])) {
			@pvp['team'][@pvp['players'][player()]['team']]['captain'] = ''
			_class('unload', player(), @pvp['players'][player()]['class'])
			@pvp['players'][player()]['class'] = @pvp['arena']['classes'][@pvp['players'][player()]['team']][0]
			_class('load', player(), @pvp['players'][player()]['class'])
			_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color'])
				.to_upper(@pvp['arena']['team'][@pvp['players'][player()]['team']]['name']).color('r').' - Captain has died and dropped his hat!')
			foreach(@pvp['players'], @p, @player) {
				if(@player['team'] == @pvp['players'][player()]['team']) {
					set_compass_target(@p, ploc())
				}
			}
			
			if(@e['cause']['cause'] == 'VOID' || @e['cause']['cause'] == 'LAVA') {
				_pvp_hat_spawn(@id, @pvp['players'][player()]['team'])
			} else {
				_pvp_hat_spawn(@id, @pvp['players'][player()]['team'], _relative(ploc(), 'up'))
			}
		} else if(!array_index_exists(@pvp['arena'], 'denydrop') 
		|| array_index_exists(@pvp['arena'], 'denydrop')
		&& is_array(@pvp['arena']['denydrop'])
		&& !array_contains(@pvp['arena']['denydrop'], @drop['type'])) {
			array_push(@drops, @drop)
		}
	}
	
	modify_event('drops', @drops)
	modify_event('xp', null)
	_pvp_check_objectives(@id)
}

array_push(@pvp['binds'], @id.'quit')
bind('player_quit', array('id': @id.'quit'), null, @e, @id = @id, @host = player()) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()),
		die())
		
	if(player() == @host) {
		console('Host ('.@host.') left the match in '.@id.'.')
	}

	if(@pvp['arena']['mode'] == 'ctf' 
	&& pinv(player(), 103) != null 
	&& (pinv(player(), 103)['type'] == 8 
	|| pinv(player(), 103)['type'] == 10)) {
		_pvp_flag_spawn(@id, if(pinv(player(), 103)['type'] == 10, 0, 1)) 
	}

	if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode'])) {
		@messagecolor = @pvp['arena']['team'][@pvp['players'][player()]['team']]['color']
	} else {
		@messagecolor = 'white'
	}
	modify_event('message', color('gray').'[PVP] '.color(@messagecolor).@e['message'])
	if(array_index_exists(@pvp['players'][player()], 'class')) {
		_class('unload', player(), @pvp['players'][player()]['class'])
	}
	array_remove(@pvp['players'], player())
	_pvp_check_objectives(@id)
	
	bind('player_join', null, array('player': player()), @e, @id = @id) {
		@pvp = import('pvp'.@id)
		if(@pvp && @pvp['running'] == 'true' && pworld() == 'custom') {
			set_ploc(@pvp['arena']['lobby'])
			_clear_pinv()
		}
		unbind()
	}
}

array_push(@pvp['binds'], @id.'spawn')
bind('player_spawn', array('id': @id.'spawn'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), 
		die())

	set_timeout(50, closure(){ # workaround for bug where players retain potion effects after death
		_clear_peffects(player())
	})
	if(!array_index_exists(@pvp['arena'], 'respawntime')) {
		set_timeout(100, closure(){
			_pvp_equip(@id, player())
		})
	} else if(array_index_exists(@pvp['arena'], 'classes')) {
		if(array_index_exists(@pvp, 'team')
		&& array_size(@pvp['arena']['classes'][@pvp['players'][player()]['team']]) > 1) {
			set_timeout(50, closure(){
				popen_virtualchest(@id.@pvp['players'][player()]['team'])
			})
		} else if(array_size(@pvp['arena']['classes'][0]) > 1) {
			set_timeout(50, closure(){
				popen_virtualchest(@id.'0')
			})
		}
	}

	if(array_index_exists(@pvp['arena'], 'respawntime')) {
		set_timeout(50, closure(){
			msg(color('gray').'[PVP] '.color('r').'You will respawn in at least '
				.round((@pvp['players'][player()]['respawn'] - time()) / 1000).' seconds.')
		})
	} else if(array_index_exists(@pvp, 'team')) {
		@r = rand(0, array_size(@pvp['arena']['spawn'][@pvp['players'][player()]['team']]))
		modify_event('location', @pvp['arena']['spawn'][@pvp['players'][player()]['team']][@r])
	} else {
		@r = rand(0, array_size(@pvp['arena']['spawn'][0]))
		# if(!array_index_exists(@arena, 'spawnblock') || get_block_at(@pvp['arena']['spawn'][0][@r]) == @arena['spawnblock'][0]) {
			modify_event('location', @pvp['arena']['spawn'][0][@r])
		# } else {
			# @spawned = false
			# for(@i = 0, @i < array_size(@pvp['arena']['spawn'][0]), @i++,
				# if(get_block_at(@pvp['arena']['spawn'][0][@i]) == @arena['spawnblock'][0]) {
					# modify_event('location', @pvp['arena']['spawn'][0][@i])
					# break()
				# }
			# )
		# }
	}
	

}

# allow use of enderpearls in PVP arenas (overrides main.ms cancel)
array_push(@pvp['binds'], @id.'interactpearls')
bind('player_interact', array('id': @id.'interactpearls', 'priority': 'high'), array('button': 'right', 'item': 368), @e) {
	consume()
}

if(array_index_exists(@pvp['arena'], 'chestspawn')) {
	array_push(@pvp['binds'], @id.'interactchest')
	bind('player_interact', array('id': @id.'interactchest'), array('block': 54), @e, @id = @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), 
			die())

		@chestloc = array(
			integer(@e['location'][0]), 
			integer(@e['location'][1]), 
			integer(@e['location'][2]), 
			@e['location'][3]
		)
		for(@i = 0, @i < array_size(@pvp['arena']['chestspawn']), @i++) {
			if(@pvp['arena']['chestspawn'][@i]['loc'] == @chestloc
			&& array_index_exists(@pvp['arena']['chestspawn'][@i], 'cooldown')) {
				cancel()
				set_block_at(@e['location'], 0)
				make_effect(@e['location'], 'STEP_SOUND:54')
				@pvp['chestspawn'][@i] = time()
				break()
			}
		}
	}
}

if(array_index_exists(@pvp['arena'], 'mobspawn')) {
	array_push(@pvp['binds'], @id.'NoMobXP')
	bind('entity_death', array('id': @id.'NoMobXP'), null, @e, @id = @id) {
		@pvp = import('pvp'.@id)
		if(array_contains(sk_regions_at(@e['location']), @pvp['arena']['region'])) {
			modify_event('xp', 0)
		}
	}
}

if(array_index_exists(@pvp['arena'], 'mobprotect')) {
	array_push(@pvp['binds'], @id.'MobDeath')
	bind('entity_death', array('id': @id.'MobDeath'), null, @e, @id = @id) {
		@pvp = import('pvp'.@id)
		@uuid = entity_uuid(@e['id'])
		if(array_index_exists(@pvp['team'][0], 'mobprotect') && @uuid == @pvp['team'][0]['mobprotect']) {
			_pvp_end_match(@id, @pvp['team'][1]['players'])
		} else if(array_index_exists(@pvp['team'][1], 'mobprotect') && @uuid == @pvp['team'][1]['mobprotect']) {
			_pvp_end_match(@id, @pvp['team'][0]['players'])
		}
	}
}

array_push(@pvp['binds'], @id.'enderpearl')
bind('player_teleport', array('id': @id.'enderpearl', 'priority': 'highest'), array('type': 'ENDER_PEARL'), @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), 
		die())
		
	if(!array_contains(sk_regions_at(@e['to']), @pvp['arena']['region'])) {
		cancel()
		consume()
	}
}

array_push(@pvp['binds'], @id.'command')
bind('player_command', array('id': @id.'command'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player())
	|| !array_contains(array('/accept', '/warp', '/spawn', '/home'), @e['prefix']), die())
	if(array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode'])) {
		_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
			.color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color']).player().color('r').' left the arena.')
	} else {
		_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '.color('r').player().' left the arena.')
	}
	if(@pvp['arena']['mode'] == 'ctf' 
	&& pinv(player(), 103) 
	&& (pinv(player(), 103)['type'] == 8 
	|| pinv(player(), 103)['type'] == 10)) {
		_pvp_flag_spawn(@id, if(pinv(player(), 103)['type'] == 10, 0, 1))
	}
	if(array_index_exists(@pvp['players'][player()], 'class')) {
		_class('unload', player(), @pvp['players'][player()]['class'])
	}
	if(array_index_exists(@pvp['arena'], 'timer') && phas_bar()) {
		premove_bar()
	}
	array_remove(@pvp['players'], player())
	_clear_pinv()
	_clear_peffects(player())
	_pvp_check_objectives(@id)
}

if(!array_contains(@pvp['arena']['flags'], 'build')) {
	array_push(@pvp['binds'], @id.'break')
	bind('block_break', array('id': @id.'break'), null, @e, @id = @id) {
		@pvp = import('pvp'.@id)
		if(array_index_exists(@pvp['players'], player()), 
			cancel())
	}
}

array_push(@pvp['binds'], @id.'damage')
bind('entity_damage_player', array('id': @id.'damage'), null, @e, @id = @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), die())

	if(array_index_exists(@pvp['players'], @e['data'])) {
		array_push(@pvp['stats'][player()]['damagetaken'], array(@e['data'], @e['amount']))
	}
	
	if(@e['damager'] == 'PLAYER' || @e['damager'] == 'ARROW' || @e['damager'] == 'WITHER_SKULL' || @e['damager'] == 'SNOWBALL') {
		if(!@pvp['arena']['ff']
		&& array_index_exists(@pvp['players'], @e['data'])
		&& (array_contains(array('dm', 'koth'), @pvp['arena']['mode']) 
		|| @pvp['players'][player()]['team'] == @pvp['players'][@e['data']]['team'])) {
			cancel()
		} else if(@e['damager'] == 'WITHER_SKULL') {
			modify_event('amount', @e['amount'] * 6)
			set_timeout(150, closure(set_peffect(player(), 20, 0, 0)))
		}
		if(!array_index_exists(@pvp['players'], @e['data']) && ponline(@e['data'])) {
			set_ploc(@e['data'], @pvp['arena']['lobby'])
		}
	}
}

if(array_contains(@pvp['arena']['flags'], 'noinventory')) {
	array_push(@pvp['binds'], @id.'noinventory')
	bind('inventory_click', array('id': @id.'noinventory'), null, @e, @id = @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), 
			die())
			
		cancel()
	}
} else if(@pvp['arena']['mode'] == 'ctf') {
	array_push(@pvp['binds'], @id.'flagclick')
	bind('inventory_click', array('id': @id.'flagclick'), array('slottype': 'ARMOR'), @e, @id = @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		
		if(@e['slotitem']['type'] == 10 || @e['slotitem']['type'] == 8, 
			cancel())
	}
}

if(array_contains(@pvp['arena']['flags'], 'rallycall')) {
	array_push(@pvp['binds'], @id.'rallycall')
	bind('player_interact', array('id': @id.'rallycall'), array('item': 401, 'button': 'right'), @e, @id = @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player())
		|| @e['action'] != 'right_click_block', 
			die())
			
		cancel()
		if(!@loc = _relative(@e['location'], @e['facing']), die())
		@loc = array(@loc[0] + 0.5, @loc[1], @loc[2] + 0.5, @loc[3])
		launch_firework(@loc, array(
			'strength': 3, 
			'flicker': true, 
			'trail': true, 
			'colors': array('RED'), 
			'type': 'BURST')
		)
		set_timeout(3000, closure(){
			if(@pvp['players'][player()]['respawn'] == 0) {
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
					.color(@pvp['arena']['team'][@pvp['players'][player()]['team']]['color'])
					.player().color('r').' rallied his crew!')
				foreach(array_keys(@pvp['players']), @p) {
					if(@p != player()
					&& @pvp['players'][player()]['team'] == @pvp['players'][@p]['team']
					&& pinfo(@p, 5) > 0
					&& @pvp['players'][@p]['respawn'] == 0) {
						set_ploc(@p, ploc(player()))
					}
				}
			}
		})
	}
}

if(array_contains(@pvp['arena']['flags'], 'stackedpickup') 
|| @pvp['arena']['mode'] == 'ctf' 
|| array_index_exists(@pvp['arena'], 'captain')) {
	array_push(@pvp['binds'], @id.'pickup')
	bind('item_pickup', array('id': @id.'pickup'), null, @e, @id = @id) { 
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), 
			die())
			
		if(@e['item']['type'] == '10') {
			if(@pvp['players'][player()]['team'] == 0) {
				if(_horizontal_distance(ploc(), @pvp['arena']['ctfflag'][0]) > 3) { 
					queue_clear(@id.'0flag')
					modify_event('item', null)
					_pvp_flag_spawn(@id, 0)
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
						.color(@pvp['arena']['team'][0]['color']).player().color('r').' returned the '
						.color(@pvp['arena']['team'][0]['color']).'flag')
					play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 0))
				} else {
					cancel()
					if(pinv(player(), 103) != null && pinv(player(), 103)['type'] == 8) {
						play_sound(@pvp['arena']['ctfflag'][0], array('sound': 'ZOMBIE_METAL', 'volume': 3))
						@pvp['team'][0]['score']++
						set_pscore('captures', to_lower(@pvp['arena']['team'][0]['name']), @pvp['team'][0]['score'], @id)
						set_pinv(player(), array(103: null))
						_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
							.color(@pvp['arena']['team'][0]['color']).player().color('r').' secured the '
							.color(@pvp['arena']['team'][1]['color']).'flag'.color('r').'!')
						if(array_index_exists(@pvp['arena'], 'rsoutputscore')) {
							set_block_at(@pvp['arena']['rsoutputscore'][0], '76:5')
							set_timeout(1000, closure(){
								set_block_at(@pvp['arena']['rsoutputscore'][0], '50:5')
							})
						}
						export('pvp'.@id, @pvp)
						_pvp_flag_spawn(@id, 1)
						_pvp_check_objectives(@id)
					}
				}
			} else {
				queue_clear(@id.'0flag')
				modify_event('item', null)
				set_pinv(player(), array(103: array('type': 10, 'qty': 1)))
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
					.color(@pvp['arena']['team'][1]['color']).player().color('r').' picked up the '
					.color(@pvp['arena']['team'][0]['color']).'flag')
				play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'volume': 3))
			}
		} else if(@e['item']['type'] == '8') {
			if(@pvp['players'][player()]['team'] == 1) {
				if(_horizontal_distance(ploc(), @pvp['arena']['ctfflag'][1]) > 3) {
					queue_clear(@id.'1flag')
					modify_event('item', null)
					_pvp_flag_spawn(@id, 1)
					_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
						.color(@pvp['arena']['team'][1]['color']).player().color('r').' returned the '
						.color(@pvp['arena']['team'][1]['color']).'flag')
					play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 0))
				} else {
					cancel()
					if(pinv(player(), 103) != null && pinv(player(), 103)['type'] == 10) {
						set_pinv(player(), array(103: null))
						play_sound(@pvp['arena']['ctfflag'][1], array('sound': 'ZOMBIE_METAL', 'volume': 3))
						@pvp['team'][1]['score']++
						set_pscore('captures', to_lower(@pvp['arena']['team'][1]['name']), @pvp['team'][1]['score'], @id)
						_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
							.color(@pvp['arena']['team'][1]['color']).player().color('r').' secured the '
							.color(@pvp['arena']['team'][0]['color']).'flag'.color('r').'!')
						if(array_index_exists(@pvp['arena'], 'rsoutputscore')) {
							set_block_at(@pvp['arena']['rsoutputscore'][1], '76:5')
							set_timeout(1000, closure(){
								set_block_at(@pvp['arena']['rsoutputscore'][1], '50:5')
							})
						}
						export('pvp'.@id, @pvp)
						_pvp_flag_spawn(@id, 0)
						_pvp_check_objectives(@id)
					}
				}
			} else {
				queue_clear(@id.'1flag')
				modify_event('item', null)
				set_pinv(player(), array(103: array('type': 8, 'qty': 1)))
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
					.color(@pvp['arena']['team'][0]['color']).player().color('r').' picked up the '
					.color(@pvp['arena']['team'][1]['color']).'flag')
				play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'volume': 3))
			}
		} else if(array_index_exists(@pvp['arena'], 'captain')
		&& @e['item']['type'] == @pvp['team'][0]['captainhat']['type']) {
			if(@pvp['players'][player()]['team'] == 0) {
				modify_event('item', null)
				_class('unload', player(), @pvp['players'][player()]['class'])
				_clear_pinv()
				_clear_peffects()
				queue_clear(@id.'0hat')
				@pvp['players'][player()]['class'] = @pvp['arena']['captain'][0]
				@pvp['team'][0]['captain'] = player()
				_class('load', player(), @pvp['arena']['captain'][0])
				_class('equip', player(), @pvp['arena']['captain'][0])
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
					.color(@pvp['arena']['team'][0]['color']).player().color('r').' became the new captain!')
				clear_virtualchest(@id.'0', 0)
			} else {
				cancel()
			}
			
		} else if(array_index_exists(@pvp['arena'], 'captain')
		&& @e['item']['type'] == @pvp['team'][1]['captainhat']['type']) {
			if(@pvp['players'][player()]['team'] == 1) {
				modify_event('item', null)
				_class('unload', player(), @pvp['players'][player()]['class'])
				_clear_pinv()
				_clear_peffects()
				queue_clear(@id.'1hat')
				@pvp['players'][player()]['class'] = @pvp['arena']['captain'][1]
				@pvp['team'][1]['captain'] = player()
				_class('load', player(), @pvp['arena']['captain'][1])
				_class('equip', player(), @pvp['arena']['captain'][1])
				_regionmsg(@pvp['arena']['broadcast'], color('gray').'[PVP] '
					.color(@pvp['arena']['team'][1]['color']).player().color('r').' became the new captain!')
				clear_virtualchest(@id.'1', 0)
			} else {
				cancel()
			}
		} else if(max_stack_size(@e['item']) == 1) {
			if(array_contains(@pvp['arena']['flags'], 'stackedpickup') 
			&& array_index_exists(@pvp['players'], player())) {
				foreach(pinv(), @slot, @item) {
					if(@item != null 
					&& @e['item']['type'] == @item['type'] 
					&& @e['item']['type'] != '373' 
					&& @e['item']['enchants'] == @item['enchants']) {
						if(@item['data'] > @e['item']['data']) {
							set_inventory_item(pinfo()[13], @slot, @e['item'])
						}
						modify_event('item', null)
						break()
					}
				}
			}
		}
	}
}

if(@pvp['arena']['mode'] == 'ctf' || array_index_exists(@pvp['arena'], 'captain')) {
	array_push(@pvp['binds'], @id.'protectdrops')
	bind('entity_damage', array('id': @id.'protectdrops'), array('type': 'DROPPED_ITEM', 'cause': 'BLOCK_EXPLOSION'), 
	@e, @region = @pvp['arena']['region']) {
		if(array_contains(sk_regions_at(entity_loc(@e['id'])), @region)) {
			cancel()
		}
	}
}

if(array_contains(@pvp['arena']['flags'], 'infinitedispensers')) {
	array_push(@pvp['binds'], @id.'infinitedispensers')
	bind('projectile_hit', array('id': @id.'infinitedispensers'), array('type': 'ARROW'), @e) {
		if(@e['location']['world'] == 'custom' && !@e['shooter']) {
			entity_remove(@e['id'])
		}
	}
}